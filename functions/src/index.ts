import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

const ESPN_URL = "http://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard";

export const pollLiveMatchesV1 = functions.pubsub.schedule("every 1 minutes").onRun(async (context) => {
  try {
    const response = await axios.get(ESPN_URL);
    const data = response.data;
    if (!data.events || data.events.length === 0) {
      return null;
    }

    const liveEvents = data.events.filter((e: any) => {
      const state = e.status?.type?.state;
      const name = e.status?.type?.name;
      return state === "in" || name === "STATUS_HALFTIME";
    });

    if (liveEvents.length === 0) {
      return null;
    }

    const db = admin.firestore();
    const scoresRef = db.collection("system").doc("live_scores");
    const docSnap = await scoresRef.get();
    const cachedScores = docSnap.exists ? docSnap.data() || {} : {};

    let hasChanges = false;
    const newScores = { ...cachedScores };

    for (const e of liveEvents) {
      const espnId = e.id;
      const comp = e.competitions?.[0];
      if (!comp || !comp.competitors) continue;

      const home = comp.competitors.find((c: any) => c.homeAway === "home");
      const away = comp.competitors.find((c: any) => c.homeAway === "away");
      if (!home || !away) continue;

      const scoreStr = `${home.score}-${away.score}`;
      const previousScoreObj = cachedScores[espnId];
      const previousScoreStr = previousScoreObj ? previousScoreObj.score : null;

      const liveData = {
        score: scoreStr,
        clock: e.status.displayClock || "0'",
        period: e.status.period?.toString() || "1",
        status: e.status.type?.state || "in", // "pre", "in", "post"
        detail: e.status.type?.name || "STATUS_IN_PROGRESS" // e.g. "STATUS_HALFTIME", "STATUS_FULL_TIME"
      };

      newScores[espnId] = liveData;
      hasChanges = true;

      if (previousScoreStr !== scoreStr) {
        if (previousScoreStr) {
          const homeName = home.team?.name || "Home";
          const awayName = away.team?.name || "Away";
          
          console.log(`Goal detected for ${espnId}: ${homeName} ${home.score} - ${away.score} ${awayName}`);

          const message = {
            notification: {
              title: `⚽ BUUUUT !`,
              body: `${homeName} ${home.score} - ${away.score} ${awayName}`,
            },
            data: {
              matchId: `espn_${espnId}`,
              action: `match_espn_${espnId}`,
              type: "goal",
            },
            condition: `'match_${espnId}' in topics || 'team_${home.team?.abbreviation}' in topics || 'team_${away.team?.abbreviation}' in topics`
          };

          try {
            await admin.messaging().send(message);
          } catch (err) {
            console.error(`Error sending push for ${espnId}`, err);
          }
        }
      }
    }

    // Always send the silent data message for the live ticker if there are live events
    if (liveEvents.length > 0) {
       const tickerMessage = {
         data: {
           action: "live_ticker",
           payload: JSON.stringify(newScores) // Send the entire live map
         },
         topic: "live_ticker"
       };
       try {
         await admin.messaging().send(tickerMessage);
       } catch (err) {
         console.error("Error sending live_ticker", err);
       }
    }

    // Update Firestore with the new clock/score states
    if (hasChanges) {
      await scoresRef.set(newScores, { merge: true });
    }

  } catch (error) {
    console.error("Error polling ESPN", error);
  }
  return null;
});
