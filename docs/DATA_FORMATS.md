# Mortar Calculator - Data Formats

## Ballistic Table Format

```json
{
  "mortar": "M252",
  "description": "81mm mortar",
  "charges": [
    {
      "charge": 0,
      "minRange": 100,
      "maxRange": 1000,
      "table": [
        {"range": 100, "elevation": 1520, "tof": 11.5, "drift": 0.5}
      ]
    }
  ]
}
```

### Fields
- `mortar`: Mortar type identifier
- `charge`: Charge number (0-3)
- `range`: Distance in meters
- `elevation`: Elevation in NATO mils (0-1600)
- `tof`: Time of flight in seconds
- `drift`: Lateral drift in mils (optional)

---

## Map Metadata Format

```json
{
  "name": "Everon",
  "image": "map.png",
  "worldSize": 10240,
  "gridSize": 100,
  "pixelsPerMeter": 0.5,
  "minElevation": 0,
  "maxElevation": 250
}
```

### Fields
- `name`: Map display name
- `image`: Map image filename
- `worldSize`: World size in meters (square)
- `gridSize`: Grid cell size in meters
- `pixelsPerMeter`: Image scale factor

---

## Heightmap Format

```json
{
  "format": "Heightmap_1.0",
  "width": 1024,
  "height": 1024,
  "worldSize": 10240,
  "minElevation": 0,
  "maxElevation": 250,
  "data": "<base64_or_file>"
}
```

### Support
- PNG Grayscale (8/16 bit)
- Raw float32 binary
- JSON Base64 encoded

---

## Fire Mission Format

```json
{
  "id": "mission_001",
  "name": "Fire Mission Alpha",
  "mortarType": "M252",
  "mortarPosition": {"x": 1234, "y": 5678, "altitude": 45},
  "targets": [
    {
      "id": "t1",
      "name": "Bunker",
      "position": {"x": 2000, "y": 3000, "altitude": 50},
      "priority": 1
    }
  ]
}
```

---

## Coordinate Systems

### Grid Reference (6-digit)
`012 345` = 12300m East, 34500m North

### Quick Entry (6-digit)
`012345` = Grid reference without spaces

### Raw Coordinates
`X: 12345.6 Y: 78901.2` = Full meter precision

---

## File Structure

```
assets/
├── tables/
│   ├── m252.json
│   ├── 2b14.json
│   └── m224.json
├── maps/
│   └── everon/
│       ├── metadata.json
│       ├── map.png
│       └── heightmap.png
└── missions/
    └── example.json
```
