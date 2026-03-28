# Fire Mission Workflow Example

## Scenario
Fire mission to destroy 3 enemy positions with mortar section

## Setup
- Mortar: M252 at grid `012 345`
- Target 1: Bunker at `015 350` - Priority 1
- Target 2: Machine Gun at `018 348` - Priority 2  
- Target 3: Observation Post at `014 352` - Priority 3

## Step-by-Step

### 1. Create Fire Mission
```
Fire Mission: "OPFOR Assault"
Mortar: M252
Position: 012 345
```

### 2. Add Targets
```
Target 1: Bunker
- Grid: 015 350
- Priority: 1
- Rounds: 6

Target 2: Machine Gun
- Grid: 018 348
- Priority: 2
- Rounds: 4

Target 3: Observation Post
- Grid: 014 352
- Priority: 3
- Rounds: 4
```

### 3. Calculate Solutions
```
Target 1: AZ 3240, EL 1422, CH 2, DST 845m, TOF 27s
Target 2: AZ 3010, EL 1380, CH 2, DST 920m, TOF 29s
Target 3: AZ 3450, EL 1450, CH 2, DST 720m, TOF 24s
```

### 4. Execute Mission
```
Fire Target 1 (Bunker)
→ 6 rounds fired
→ Impact: 27s

Fire Target 2 (Machine Gun)
→ 4 rounds fired
→ Impact: 29s

Fire Target 3 (Observation Post)
→ 4 rounds fired
→ Impact: 24s
```

### 5. Mission Complete
Total time: ~80 seconds
Total rounds: 14

---

## Shot Correction Example

### Initial Fire
```
Target: Bunker
Solution: AZ 3240, EL 1422
```

### Observer Call
```
"DROP 50, RIGHT 30"
```

### Apply Correction
```
Original: EL 1422
Correction: -50m = -100 mils
New: EL 1322

Original: AZ 3240
Correction: RIGHT 30 mils
New: AZ 3270
```

### Corrected Solution
```
New: AZ 3270, EL 1322
```

---

## Fire Mission JSON

```json
{
  "id": "fm_001",
  "name": "OPFOR Assault",
  "mortarType": "M252",
  "mortarPosition": {"x": 12300, "y": 34500, "altitude": 45},
  "targets": [
    {
      "id": "t1",
      "name": "Bunker",
      "position": {"x": 15600, "y": 35000, "altitude": 50},
      "priority": 1,
      "solution": {
        "azimuth": 3240,
        "elevation": 1422,
        "charge": 2,
        "distance": 845,
        "timeOfFlight": 27
      }
    },
    {
      "id": "t2",
      "name": "Machine Gun",
      "position": {"x": 18900, "y": 34800, "altitude": 48},
      "priority": 2,
      "solution": {
        "azimuth": 3010,
        "elevation": 1380,
        "charge": 2,
        "distance": 920,
        "timeOfFlight": 29
      }
    }
  ],
  "status": "completed",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

---

## Quick Fire Mission Commands

| Command | Description |
|---------|-------------|
| `ADD [meters]` | Increase range |
| `DROP [meters]` | Decrease range |
| `LEFT [mils]` | Decrease azimuth |
| `RIGHT [mils]` | Increase azimuth |
| `FIRE` | Execute current target |
| `NEXT` | Move to next target |
| `REPEAT` | Fire again |
| `END` | End mission |
