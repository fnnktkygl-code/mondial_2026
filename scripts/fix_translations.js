const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '../lib/l10n/translations.dart');
let content = fs.readFileSync(filePath, 'utf8');

// Extraction des blocs de langues
const languages = ['fr', 'en', 'es'];

languages.forEach(lang => {
    const startMarker = `'${lang}': {`;
    const startIndex = content.indexOf(startMarker) + startMarker.length;
    let braceCount = 1;
    let endIndex = startIndex;
    
    while (braceCount > 0 && endIndex < content.length) {
        if (content[endIndex] === '{') braceCount++;
        if (content[endIndex] === '}') braceCount--;
        endIndex++;
    }
    
    const blockContent = content.substring(startIndex, endIndex - 1);
    const lines = blockContent.split('\n');
    const uniqueLines = [];
    const seenKeys = new Set();
    
    lines.forEach(line => {
        const match = line.match(/'([^']+)':/);
        if (match) {
            const key = match[1];
            if (!seenKeys.has(key)) {
                seenKeys.add(key);
                uniqueLines.push(line);
            }
        } else {
            uniqueLines.push(line);
        }
    });
    
    const newBlockContent = uniqueLines.join('\n');
    content = content.substring(0, startIndex) + newBlockContent + content.substring(endIndex - 1);
});

fs.writeFileSync(filePath, content);
console.log('Doublons supprimés avec succès.');
