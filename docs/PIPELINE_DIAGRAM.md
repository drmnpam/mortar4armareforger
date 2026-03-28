# Ballistic Calculation Pipeline

## Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     INPUT COLLECTION                                 │
│                                                                     │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐         │
│   │Mortar Pos    │    │Target Pos    │    │Mortar Type   │         │
│   │(X, Y, Alt)   │───▶│(X, Y, Alt)   │───▶│(M252, etc)   │         │
│   └──────────────┘    └──────────────┘    └──────────────┘         │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     CALCULATION PIPELINE                             │
│                                                                     │
│  ┌─────────────┐                                                    │
│  │  STEP 1     │  Distance Calculation                              │
│  │             │  distance = sqrt((x2-x1)² + (y2-y1)²)             │
│  └──────┬──────┘                                                    │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────┐                                                    │
│  │  STEP 2     │  Azimuth Calculation                               │
│  │             │  azimuth = atan2(dx, dy) * 1018.5916              │
│  └──────┬──────┘  normalize to 0-6400                              │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────┐                                                    │
│  │  STEP 3     │  Charge Selection                                  │
│  │             │  Find lowest charge that can reach                 │
│  └──────┬──────┘                                                    │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────┐                                                    │
│  │  STEP 4     │  Table Lookup                                      │
│  │             │  Load ballistic table for mortar/charge            │
│  └──────┬──────┘                                                    │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────┐                                                    │
│  │  STEP 5     │  Elevation Interpolation                           │
│  │             │  Linear interpolation between table rows            │
│  └──────┬──────┘                                                    │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────┐                                                    │
│  │  STEP 6     │  Height Correction                                 │
│  │             │  site = deltaH / distance                         │
│  └──────┬──────┘  corrected = elevation + site * 1000             │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────┐                                                    │
│  │  STEP 7     │  Time of Flight                                    │
│  │             │  Interpolate TOF from table                        │
│  └──────┬──────┘  adjust for height difference                     │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────┐                                                    │
│  │  STEP 8     │  Generate Correction Notes                         │
│  │             │  Danger close, max range, height adj              │
│  └──────┬──────┘                                                    │
│         │                                                           │
└─────────┼───────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     OUTPUT GENERATION                              │
│                                                                     │
│   ┌─────────────────────────────────────────────────────────┐        │
│   │            FIRING SOLUTION OBJECT                        │        │
│   ├─────────────────────────────────────────────────────────┤        │
│   │  azimuth: 3240 mils                                     │        │
│   │  elevation: 1422 mils                                   │        │
│   │  charge: 2                                              │        │
│   │  distance: 845 m                                        │        │
│   │  timeOfFlight: 27.0 s                                   │        │
│   │  heightDifference: +15 m                                │        │
│   │  heightAdjusted: true                                   │        │
│   │  correction: "HEIGHT UP: +18.5 mils"                     │        │
│   └─────────────────────────────────────────────────────────┘        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Coordinate Conversion Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                     COORDINATE PIPELINE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   GRID              METERS              PIXELS                   │
│  ┌────────┐        ┌────────┐        ┌────────┐                  │
│  │012 345 │───────▶│(x, y)  │───────▶│(px, py)│                  │
│  └────────┘        └────────┘        └────────┘                  │
│       ▲                │                │                         │
│       │                │                │                         │
│       └────────────────┴────────────────┘                         │
│                    Converter                                       │
│                    - gridToMeters()                                │
│                    - metersToPixels()                              │
│                    - pixelsToMeters()                              │
│                    - metersToGrid()                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Fire Mission Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    FIRE MISSION FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  CREATE MISSION                                                  │
│  ├── Set mortar position                                         │
│  ├── Select mortar type                                          │
│  └── Name mission                                                │
│         │                                                        │
│         ▼                                                        │
│  ADD TARGETS ────────┐                                           │
│  ├── Target 1        │                                           │
│  ├── Target 2        │                                           │
│  └── Target 3        │                                           │
│         │            │                                           │
│         ▼            │                                           │
│  CALCULATE ALL ──────┘                                           │
│  ├── For each target:                                            │
│  │   ├── Calculate distance                                      │
│  │   ├── Calculate azimuth                                       │
│  │   ├── Select charge                                           │
│  │   ├── Interpolate elevation                                   │
│  │   ├── Apply height correction                                 │
│  │   └── Store solution                                          │
│  └── Sort by priority                                            │
│         │                                                        │
│         ▼                                                        │
│  EXECUTE MISSION                                                 │
│  ├── Fire Target 1                                               │
│  │   ├── Display solution                                        │
│  │   ├── Start timer                                             │
│  │   └── Mark as FIRED                                           │
│  ├── Apply correction (if needed)                               │
│  ├── Fire Target 2                                               │
│  └── Fire Target 3                                               │
│         │                                                        │
│         ▼                                                        │
│  MISSION COMPLETE                                                │
│  ├── Summary stats                                               │
│  └── Save to history                                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Shot Correction Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                   SHOT CORRECTION FLOW                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  OBSERVER INPUT                                                  │
│  ├── "DROP 50"                                                   │
│  ├── "ADD 30"                                                    │
│  ├── "LEFT 40"                                                   │
│  └── "RIGHT 20"                                                  │
│         │                                                        │
│         ▼                                                        │
│  PARSER                                                          │
│  ├── Parse observer call                                         │
│  ├── Extract values                                              │
│  └── Validate commands                                           │
│         │                                                        │
│         ▼                                                        │
│  APPLY CORRECTION                                                │
│  ├── Range correction (ADD/DROP)                                │
│  │   └── elevationChange = meters * milsPerMeter               │
│  ├── Deflection correction (LEFT/RIGHT)                         │
│  │   └── azimuthChange = ±mils                                  │
│  └── Combine changes                                             │
│         │                                                        │
│         ▼                                                        │
│  NEW SOLUTION                                                    │
│  ├── newElevation = old + elevationChange                      │
│  ├── newAzimuth = old + azimuthChange                           │
│  └── estimatedNewImpact (visualization)                        │
│         │                                                        │
│         ▼                                                        │
│  OUTPUT                                                          │
│  ├── Display new solution                                        │
│  ├── Show correction description                                │
│  └── Update impact visualization                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Heightmap Integration

```
┌─────────────────────────────────────────────────────────────────┐
│                   HEIGHTMAP PIPELINE                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  LOAD HEIGHTMAP                                                  │
│  ├── Parse PNG/RAW file                                          │
│  ├── Extract pixel values                                        │
│  └── Normalize to elevation range                               │
│         │                                                        │
│         ▼                                                        │
│  QUERY ELEVATION                                                 │
│  ├── Input: Position (x, y)                                      │
│  ├── Convert to pixel coordinates                                │
│  ├── Bilinear interpolation                                       │
│  └── Return: altitude                                            │
│         │                                                        │
│         ▼                                                        │
│  AUTO-ALTITUDE                                                   │
│  ├── When placing marker:                                        │
│  │   ├── Get marker x, y                                        │
│  │   ├── Query heightmap                                         │
│  │   └── Set marker.altitude = elevation                        │
│  └── When calculating:                                           │
│      ├── Get mortar altitude                                     │
│      ├── Get target altitude                                     │
│      └── Calculate height difference                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```
