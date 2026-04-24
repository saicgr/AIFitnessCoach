"""Generate a minimal Strava bulk-export ZIP fixture for tests.
Writing this as a Python helper instead of committing a binary blob keeps
the fixture easy to audit and regenerate — run `python strava_sample.zip.py`
to regenerate `strava_sample.zip` in the same dir.
"""
import csv
import io
import os
import zipfile

OUT = os.path.join(os.path.dirname(__file__), "strava_sample.zip")

ACTIVITIES_CSV = [
    [
        "Activity ID", "Activity Date", "Activity Name", "Activity Type",
        "Elapsed Time", "Moving Time", "Distance", "Average Heart Rate",
        "Max Heart Rate", "Average Watts", "Calories", "Elevation Gain",
        "Perceived Exertion",
    ],
    [
        "11111111111", "Mar 28, 2025, 5:29:00 PM", "Sunday Run", "Run",
        "3625", "3600", "10.5", "148", "172", "", "620", "85", "7.5",
    ],
    [
        "22222222222", "Mar 30, 2025, 8:15:00 AM", "Zwift FTP", "VirtualRide",
        "3700", "3600", "35.2", "142", "168", "225", "890", "420", "8.0",
    ],
    [
        "33333333333", "Apr 02, 2025, 6:00:00 AM", "Easy recovery hike", "Hike",
        "7200", "7200", "6.3", "115", "138", "", "410", "520", "3.0",
    ],
    [
        "44444444444", "Apr 04, 2025, 6:00:00 PM", "Arms day", "WeightTraining",
        "3600", "3600", "", "125", "155", "", "280", "", "6.0",
    ],
]

GPX_TEMPLATE = """<?xml version='1.0' encoding='UTF-8'?>
<gpx version='1.1' creator='Strava' xmlns='http://www.topografix.com/GPX/1/1'>
 <trk>
  <name>Sunday Run</name>
  <type>run</type>
  <trkseg>
   <trkpt lat='37.7749' lon='-122.4194'><ele>20</ele><time>2025-03-28T17:29:00Z</time></trkpt>
   <trkpt lat='37.7750' lon='-122.4195'><ele>22</ele><time>2025-03-28T17:30:00Z</time></trkpt>
   <trkpt lat='37.7755' lon='-122.4200'><ele>23</ele><time>2025-03-28T17:35:00Z</time></trkpt>
   <trkpt lat='37.7780' lon='-122.4250'><ele>28</ele><time>2025-03-28T18:29:00Z</time></trkpt>
  </trkseg>
 </trk>
</gpx>
"""

def main():
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        csv_buf = io.StringIO()
        w = csv.writer(csv_buf)
        for row in ACTIVITIES_CSV:
            w.writerow(row)
        zf.writestr("activities.csv", csv_buf.getvalue())
        zf.writestr("activities/11111111111.gpx", GPX_TEMPLATE)
    with open(OUT, "wb") as f:
        f.write(buf.getvalue())
    print(f"Wrote {OUT} ({len(buf.getvalue())} bytes)")

if __name__ == "__main__":
    main()
