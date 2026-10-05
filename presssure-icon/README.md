# PressSure · icona dell'app («Il cuore spuntato»)

Pacchetto pronto per un progetto Android (Gradle, modulo `app`).

## Colori

| Ruolo | Colore |
|---|---|
| Sfondo (pesca) | `#FBEBD9` |
| Cuore (arancio sistolica) | `#C4581F` |
| Spunta | `#FFFFFF` |

## Contenuto

```
android/res/
  mipmap-anydpi-v26/ic_launcher.xml          icona adattiva (Android 8+)
  mipmap-anydpi-v26/ic_launcher_round.xml    idem, per launcher che chiedono roundIcon
  drawable/ic_launcher_foreground.xml        livello in primo piano, vettoriale 108 dp
  drawable/ic_launcher_monochrome.xml        livello a una tinta per le icone a tema (Android 13+)
  values/ic_launcher_background.xml          colore di sfondo
  mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/   PNG per Android 7.x e precedenti (48–192 px)
playstore/
  ic_launcher-playstore.png                  512×512, PNG RGB senza trasparenza, quadrato pieno
source/
  icon-*.svg                                 sorgenti vettoriali (griglia 108×108)
```

## Istruzioni per l'integrazione (Claude Code)

1. Copia il contenuto di `android/res/` in `app/src/main/res/`, sovrascrivendo i file `ic_launcher*` generati dal template di Android Studio. Elimina eventuali `mipmap-*/ic_launcher*.webp` rimasti, altrimenti vanno in conflitto con i PNG.
2. Se `values/ic_launcher_background.xml` esiste già, sostituisci solo il colore `ic_launcher_background` con `#FBEBD9`.
3. In `AndroidManifest.xml`, dentro `<application>`:
   ```xml
   android:icon="@mipmap/ic_launcher"
   android:roundIcon="@mipmap/ic_launcher_round"
   ```
4. Se `minSdk` è 26 o superiore, le cartelle `mipmap-*dpi` con i PNG si possono eliminare: basta l'icona adattiva.
5. `playstore/ic_launcher-playstore.png` **non** va nel progetto: si carica in Play Console › Scheda dello store › Icona dell'app. Google aggiunge da solo angoli arrotondati e ombra.

## Regole rispettate

- Icona adattiva su griglia 108 dp; cuore e spunta stanno nel cerchio sicuro di 66 dp, quindi nessuna forma di launcher li taglia.
- Livello monocromatico presente: il cuore è pieno e la spunta è scavata (`fillType="evenOdd"`), il sistema lo colora con il tema dell'utente.
- Nessun testo nell'icona.
