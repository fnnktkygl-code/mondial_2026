# 🏆 Prono Challenge (Mundial 2026) — Archivo Oficial y Plataforma de Pronósticos

<div align="center">

[![Idioma: Español](https://img.shields.io/badge/Idioma-Espa%C3%B1ol%20%F0%9F%87%AA%F0%9F%87%B8-orange?style=for-the-badge)](LEAME.md)
[![Language: English](https://img.shields.io/badge/Language-English%20%F0%9F%87%AC%F0%9F%87%A7-blue?style=for-the-badge)](README.md)
[![Langue: Français](https://img.shields.io/badge/Langue-Fran%C3%A7ais%20%F0%9F%87%AB%F0%9F%87%B7-emerald?style=for-the-badge)](LISEZMOI.md)

<br/>

[![Despliegue Web](https://img.shields.io/badge/GitHub%20Pages-Desplegado%20Producci%C3%B3n-brightgreen?logo=github&style=flat-square)](https://fnnktkygl-code.github.io/mondial_2026/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x%20%7C%20Dart%203.x-02569B?logo=flutter&style=flat-square)](https://flutter.dev)
[![Arquitectura](https://img.shields.io/badge/Arquitectura-Clean%20%26%20Reactive%20Pillars-emerald?style=flat-square)](ARCHITECTURE.md)
[![Análisis Estático](https://img.shields.io/badge/Dart%20Analyze-0%20Errores%20%2F%200%20Avisos-brightgreen?style=flat-square)](ARCHITECTURE.md)
[![Pruebas Unitarias](https://img.shields.io/badge/Pruebas%20Unitarias-100%25%20Aprobadas-brightgreen?style=flat-square)](test/)
[![Formato FIFA 2026](https://img.shields.io/badge/Formato%20FIFA-104%20Partidos%20Completos-blue?style=flat-square)](assets/initial_matches.json)
[![Motor IA](https://img.shields.io/badge/IA%20Predictiva-Google%20Gemini-orange?logo=google&style=flat-square)](lib/services/genie_gemini_service.dart)
[![Licencia: MIT](https://img.shields.io/badge/Licencia-MIT-yellow.svg?style=flat-square)](LICENSE)

<p align="center">
  <strong>Prono Challenge (Mundial 2026)</strong> es una aplicación multiplataforma de vanguardia para revivir, explorar y simular la totalidad de la <strong>Copa Mundial de la FIFA 2026</strong> (48 naciones, 104 partidos, 12 grupos, dieciseisavos de final hasta la gran final).<br/>
  Desarrollada bajo los más estrictos estándares de ingeniería de software (Clean Architecture, 0 avisos del linter, pruebas automatizadas al 100%, motor de cuotas dinámicas Elo, análisis tácticos con IA Gemini y localización trilingüe completa).
</p>

[**🚀 Abrir Aplicación Web**](https://fnnktkygl-code.github.io/mondial_2026/) • [**📐 Manual de Arquitectura**](ARCHITECTURE.md) • [**🇬🇧 English README**](README.md) • [**🇫🇷 Version Française (LISEZMOI.md)**](LISEZMOI.md) • [**📊 Datos del Torneo**](assets/initial_matches.json)

</div>

---

## 📱 Galería y Vistas de la Aplicación

### 💻 Experiencia Desktop (Pantalla Grande)

<div align="center">
  <table>
    <tr>
      <td width="50%" align="center">
        <strong>🌳 Cuadro Eliminatorio Completamente Resuelto (104 Partidos)</strong><br/><br/>
        <img src="docs/screenshots/desktop_bracket.png" alt="Cuadro del Mundial 2026" width="100%" style="border-radius:12px; box-shadow:0 8px 24px rgba(0,0,0,0.4);" /><br/>
        <sub>Árbol completo de dieciseisavos a la final, conectores vectoriales fluidos y resaltado de ganadores</sub>
      </td>
      <td width="50%" align="center">
        <strong>🗓️ Calendario Interactivo y Navegación Dinámica</strong><br/><br/>
        <img src="docs/screenshots/desktop_calendar.png" alt="Calendario Desktop Mundial 2026" width="100%" style="border-radius:12px; box-shadow:0 8px 24px rgba(0,0,0,0.4);" /><br/>
        <sub>Línea temporal de 104 partidos, seguimiento en directo, filtros por fase y conversión horaria local</sub>
      </td>
    </tr>
  </table>
</div>

<br/>

### 📱 Experiencia Mobile (iPhone & Android — Galería de Vistas)

<div align="center">
  <table>
    <tr>
      <td align="center" width="25%">
        <img src="docs/screenshots/mobile_home.jpg" width="100%" style="border-radius:16px; box-shadow:0 6px 18px rgba(0,0,0,0.35);" alt="Partidos en Directo" /><br/>
        <strong>⚽ 1. Partidos</strong><br/>
        <sub>Marcadores y Fechas</sub>
      </td>
      <td align="center" width="25%">
        <img src="docs/screenshots/mobile_match_detail.jpg" width="100%" style="border-radius:16px; box-shadow:0 6px 18px rgba(0,0,0,0.35);" alt="Detalle del Partido y Alineaciones" /><br/>
        <strong>📊 2. Ficha de Partido</strong><br/>
        <sub>Alineaciones y Cuotas Elo</sub>
      </td>
      <td align="center" width="25%">
        <img src="docs/screenshots/mobile_groups.jpg" width="100%" style="border-radius:16px; box-shadow:0 6px 18px rgba(0,0,0,0.35);" alt="Clasificaciones y Grupos" /><br/>
        <strong>🏆 3. Grupos FIFA</strong><br/>
        <sub>12 Grupos y Mejores 3.º</sub>
      </td>
      <td align="center" width="25%">
        <img src="docs/screenshots/mobile_stats.jpg" width="100%" style="border-radius:16px; box-shadow:0 6px 18px rgba(0,0,0,0.35);" alt="Goleadores y Asistencias" /><br/>
        <strong>🎯 4. Bota y Asistencias</strong><br/>
        <sub>Goleadores y Pases</sub>
      </td>
    </tr>
  </table>
</div>

---

## ✨ Características Principales

| Característica | Aspectos Destacados |
| :--- | :--- |
| **🗓️ Calendario de 104 Partidos** | Línea temporal interactiva, filtros por grupo y fase, y conversión automática de zona horaria. |
| **🌳 Cuadro Eliminatorio Sin Errores** | Árbol final completo (dieciseisavos, octavos, cuartos, semifinales, 3.er puesto y final) sin marcadores de posición TBD. |
| **📊 Clasificaciones y Reglas FIFA Oficiales** | Cálculo exacto de los 12 grupos (A-L), tabla de los 8 mejores terceros y desempates estrictos (diferencia de goles, fair-play). |
| **🎯 Máximos Goleadores y Asistentes** | Tablas oficiales de la Bota de Oro y máximos asistentes con normalización de nombres de jugadores. |
| **📈 Cuotas Dinámicas y Algoritmo Elo** | Cálculo de probabilidades de victoria (1X2) y cuotas de campeón actualizadas dinámicamente partido a partido. |
| **🤖 IA Táctica Genie Gemini** | Informes detallados de cada encuentro (historial, estado físico, claves tácticas) con alternativa determinista garantizada. |
| **🌍 Paridad Trilingüe al 100%** | Cambio instantáneo sin recarga entre **Español 🇪🇸**, **Francés 🇫🇷** e **Inglés 🇬🇧**. |

---

## 🏗️ Los 5 Pilares de Ingeniería

1. **Rigor Matemático y Verdad Factual**: Conformidad al 100% con el reglamento oficial de la FIFA para el Mundial 2026 de 48 selecciones.
2. **Arquitectura Limpia y Reactiva**: Desacoplamiento total entre componentes visuales, reglas de torneo y persistencia.
3. **Cero Avisos del Linter y Pruebas Continuas**: 0 errores y 0 warnings en `dart analyze`, validado con una suite de pruebas completa.
4. **Resiliencia en IA y Control 429**: Cooldown inteligente y generación de respaldo determinista sin interrupciones.
5. **Experiencia de Usuario de Élite (WCAG AA)**: Diseño oscuro contemporáneo, animaciones fluidas a 60 FPS y adaptabilidad total.

---

## 🚀 Inicio Rápido

```bash
# 1. Clonar el repositorio
git clone https://github.com/fnnktkygl-code/mondial_2026.git
cd mondial_2026

# 2. Instalar dependencias
flutter pub get

# 3. Comprobar análisis estático (0 avisos)
flutter analyze

# 4. Ejecutar la suite de pruebas
flutter test

# 5. Iniciar la aplicación
flutter run
```

---

## 📄 Licencia

Este proyecto está distribuido bajo la licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más información.
