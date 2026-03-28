# Mortar Calculator - Beta Testing Guide

## Quick Start (30 seconds)

1. **Open app** → Tap "MAP CALCULATOR"
2. **Select map** → Choose "Everon" (or your map)
3. **Set mortar** → Tap grid icon → Enter "012 345" → Tap "Place Mortar"
4. **Set target** → Tap red marker icon → Enter "015 350" → Tap "Place Target"
5. **Fire!** → Read AZ/EL values → Tap "COPY" → Paste to Arma chat

---

## Complete Workflow

### 1. Set Mortar Position

**Option A: Grid Input (Fast)**
- Tap mortar icon (green)
- Enter 6-digit grid: `XXX YYY`
- Example: `012 345` = 12300m East, 34500m North
- Tap "CONFIRM"

**Option B: Map Tap**
- Long-press on map where mortar is located
- Select "Set as Mortar Position"

**Option C: Numeric Entry**
- Go to "NUMERIC CALCULATOR"
- Enter X: `12300`, Y: `34500`
- Altitude is optional (auto-filled if heightmap available)

### 2. Select Target

**Grid Quick Entry:**
- Tap target icon (red)
- Enter grid: `018 350`
- Tap "CONFIRM"

**Map Selection:**
- Long-press target location
- Select "Set as Target"

### 3. Read Firing Solution

The bottom panel displays:
```
AZIMUTH:  3240   (Direction in mils)
ELEVATION: 1422   (Barrel angle in mils)
CHARGE:    2      (Propellant charge)
DISTANCE:  845m   (Range to target)
TOF:       27s    (Time until impact)
```

**Tap "COPY"** to copy to clipboard in military format.

### 4. Shot Correction (If Needed)

Observer calls corrections after first round:

| Call | Meaning | Effect |
|------|---------|--------|
| "DROP 50" | 50m short | Decrease elevation |
| "ADD 30" | 30m long | Increase elevation |
| "LEFT 40" | 40 mils left | Decrease azimuth |
| "RIGHT 20" | 20 mils right | Increase azimuth |

**To apply:**
1. Tap "CORRECTION" button
2. Enter observer call
3. Tap "APPLY"
4. New solution appears automatically

### 5. Fire Mission Mode

For multiple targets:

1. Tap "FIRE MISSION"
2. Enter mission name: "Alpha Strike"
3. Add multiple targets with priorities
4. Tap "CALCULATE ALL"
5. Tap "FIRE NEXT" for each target

---

## Settings

### Units
- **Mils**: NATO 6400 (default)
- **Degrees**: Optional
- **Meters/Grid**: Toggle display format

### Mortar Type
- M252 (81mm US) - default
- 2B14 (82mm Russian)
- M224 (60mm US)

### Display Mode
- Standard (green accent)
- Night Red (NVG compatible)

### Charge Selection
- Auto (recommended) - selects optimal charge
- Manual - specify charge manually

---

## Offline Usage

The app works **completely offline**:

1. Download maps to device (Settings → Maps)
2. All ballistic tables are built-in
3. Calculations happen locally
4. No internet required for field use

---

## Tips & Tricks

### Quick Grid Entry
- Grid `012 345` = meters (X=12300, Y=34500)
- 6-digit = 100m precision
- 8-digit = 10m precision

### Height Correction
- Enter altitudes for better accuracy
- Heightmap auto-fills if available
- Look for "HEIGHT ADJ" notice

### Danger Close
- < 200m shows "DANGER CLOSE" warning
- Verify elevation > 1000 mils
- Check clearance above

### Impact Visualization
- Map shows kill/casualty zones
- Red circle = kill radius
- Orange = casualty radius
- Yellow = suppression radius

---

## Troubleshooting

### "Out of Range" Error
- Check you're using correct charge
- Verify coordinates are on map
- Max range varies by mortar type

### Wrong Solution
- Double-check mortar vs target positions
- Verify altitude values
- Try manual charge selection

### Map Not Loading
- Ensure map files are in `assets/maps/`
- Check metadata.json format
- Try re-importing map

---

## Beta Testing Checklist

### Basic Functionality
- [ ] Set mortar via grid input
- [ ] Set target via grid input
- [ ] Calculate firing solution
- [ ] Copy solution to clipboard
- [ ] Apply shot correction

### Map Features
- [ ] Load and display map
- [ ] Pan and zoom
- [ ] Place markers on map
- [ ] View impact zones
- [ ] Measure distance line

### Fire Mission
- [ ] Create fire mission
- [ ] Add multiple targets
- [ ] Calculate all solutions
- [ ] Execute sequential firing

### Settings
- [ ] Change mortar type
- [ ] Toggle auto charge
- [ ] Switch to night mode
- [ ] Export/import data

### Offline
- [ ] Enable airplane mode
- [ ] Verify calculations work
- [ ] Test map display
- [ ] Check saved targets

---

## Feedback

Report issues via:
- In-app: Settings → Feedback
- Email: [your-email]
- Discord: [your-discord]

**Include:**
- Device type (Android/iOS)
- App version
- Steps to reproduce
- Screenshot if applicable
