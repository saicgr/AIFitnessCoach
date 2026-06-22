#!/usr/bin/env python3
"""Bake the plan-preview exercise illustrations into bundled assets.

For every entry in `lib/screens/demo/preview_exercise_catalog.dart` this
downloads the exercise_library illustration from S3, resizes it to a small
thumbnail, and writes it to `assets/preview_exercises/<id>.jpg` so the plan
preview paints real, correct illustrations instantly + offline.

Run from the repo root:  python3 mobile/flutter/tool/bake_preview_exercises.py
Requires boto3 + Pillow and AWS creds in backend/.env (AWS_ACCESS_KEY_ID,
AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION, S3_BUCKET_NAME).

To add/replace an exercise: pick a media-complete exercise_library row, VISUALLY
verify its illustration matches, add `(id, s3_key)` below + a `_PEx(...)` row to
the Dart catalog, and re-run. Never add by name-match alone — vet the image.
"""
import io
import os
import sys

# (exercise_library id, S3 illustration key) — keep in sync with the Dart catalog.
ITEMS = [
    ("c0c3a2ea-a32a-4009-ba2a-f7e525efcd0a", "ILLUSTRATIONS ALL/Chest/barbell bench press.jpg"),
    ("46d54630-54c2-4931-b9be-cf98f674a32c", "ILLUSTRATIONS ALL/Chest/dumbbell fly flat bench slow.jpg"),
    ("c7291dff-122b-4ffc-a328-83afcf17e5c4", "ILLUSTRATIONS ALL/Chest/chest dip machine1.jpg"),
    ("2d5e8e30-c95f-4374-b028-1cfab5ad145b", "ILLUSTRATIONS ALL/Chest/Cable Upper Chest Crossover.jpg"),
    ("df96c033-2fca-4ea7-9b53-1f2032b37193", "ILLUSTRATIONS ALL/Chest/Clock push ups.jpg"),
    ("6b830263-650c-4fe6-890f-9b1054de5aa5", "ILLUSTRATIONS ALL/Back/Cable Close Grip Front Lat Pulldown.jpg"),
    ("e84a6b7e-ae65-44e1-bfa2-acba2306c08a", "ILLUSTRATIONS ALL/Back/seated cable row V bar machine .jpg"),
    ("3f0ab7b4-5a5e-49d3-91df-ac3256dedb2a", "ILLUSTRATIONS ALL/Shoulders/Cable Face Pull With Rope.jpg"),
    ("690e3098-8242-443e-a23d-d054c0d5b8b5", "ILLUSTRATIONS ALL/Powerlifting/Barbell Deadlift_female.jpg"),
    ("f3eee79f-f7c3-4157-8be0-070976687397", "ILLUSTRATIONS ALL/Back/Dumbbell Pendlay Row.jpg"),
    ("8ded0c32-26e2-40fd-b691-8b24f2f25497", "ILLUSTRATIONS ALL/Powerlifting/Barbell full squat.jpg"),
    ("c311314f-fbc3-47e6-ba3d-9a161738c429", "ILLUSTRATIONS ALL/Legs/Barbell front squats.jpg"),
    ("2678f51c-be2d-4b52-82bd-b86bdcb99ecf", "ILLUSTRATIONS ALL/Legs/Horizontal Leg Press.jpg"),
    ("6e264908-0c60-43b1-b174-faece9537f59", "ILLUSTRATIONS ALL/Back/Barbell romanian deadlift.jpg"),
    ("13960b56-5a88-4b9d-a14c-86b372a81d9c", "ILLUSTRATIONS ALL/Legs/Plate Overhead Walking Lunge_Female.jpg"),
    ("1e9c7040-1fe2-4edc-84e0-ae3ad61283c1", "ILLUSTRATIONS ALL/Legs/Seated leg extension_both legs.jpg"),
    ("17704a26-6918-4233-8185-7bab7461e602", "ILLUSTRATIONS ALL/Legs/lying leg curl machine  .jpg"),
    ("c88303b6-f900-481b-a769-bee0642599ad", "ILLUSTRATIONS ALL/Legs/bodyweight calf raises.jpg"),
    ("184ebc96-f304-416c-8506-95cc1d8d307f", "ILLUSTRATIONS ALL/Legs/Bulgarian Split Squat.jpg"),
    ("548be319-47a3-4b7f-830b-e64cbf0ed604", "ILLUSTRATIONS ALL/Shoulders/Barbell seated overhead press.jpg"),
    ("6e8e4f82-12d5-46f0-b929-9657ebd7e1e4", "ILLUSTRATIONS ALL/Shoulders/Dumbbell Seated Shoulder Press.jpg"),
    ("a06effca-ef7b-4c50-993f-795e0e8fb00a", "ILLUSTRATIONS ALL/Shoulders/Laying Lateral Raise.jpg"),
    ("568c24a1-97ec-4e52-b0a7-0fbd09f1496c", "ILLUSTRATIONS ALL/Shoulders/Barbell front raise.jpg"),
    ("46b3ff87-b820-49e5-b7b5-0b6f9a2503b0", "ILLUSTRATIONS ALL/Shoulders/cable rear delt fly .jpg"),
    ("45a02e57-47ee-4c27-924f-21df1575c5cb", "ILLUSTRATIONS ALL/Shoulders/arnold press dumbbell.jpg"),
    ("0256738b-b6eb-46c5-b7b4-88a11d51b5cd", "ILLUSTRATIONS ALL/Biceps/EZ Barbell Curl.jpeg"),
    ("49bb960f-1486-46ea-82ae-c96e99d443c4", "ILLUSTRATIONS ALL/Biceps/dumbbell curls.jpeg"),
    ("468e9fee-63fc-495e-b28e-b8803a4f428d", "ILLUSTRATIONS ALL/Biceps/Dumbbell Hammer Curl.jpeg"),
    ("6a311f23-7dfe-4e7a-ab60-ff4f02c29b3f", "ILLUSTRATIONS ALL/Biceps/Cable Preacher Curl.jpeg"),
    ("5efc82a2-11a6-49e3-bf44-4f882cd88668", "ILLUSTRATIONS ALL/Triceps/Cable Pushdown.jpeg"),
    ("224d012e-6c66-4b03-876c-8ab461fce31b", "ILLUSTRATIONS ALL/Abdominals/side plank.jpeg"),
    ("0d8fa338-e996-4c68-bf5d-3f0c9d91fb66", "ILLUSTRATIONS ALL/Abdominals/V crunches.jpeg"),
    ("c02b6692-b563-447e-ad76-e961db3a22fe", "ILLUSTRATIONS ALL/Abdominals/russian twist.jpeg"),
    ("085b711d-4268-445b-af27-de5d1be3b1f7", "ILLUSTRATIONS ALL/Abdominals/lying leg raise.jpeg"),
    ("6934878b-bcec-48dd-a711-1eddd7b203eb", "ILLUSTRATIONS ALL/Abdominals/Hanging Leg Raises_Female.jpg"),
    ("6bb66fde-e0ac-4792-86e0-1c261ae8fe45", "ILLUSTRATIONS ALL/Yoga/Dead Bug.jpeg"),
    ("3284b7dd-367d-471e-a1ff-ec34fcb633f9", "ILLUSTRATIONS ALL/Abdominals/mountain climbers.jpeg"),
    ("c4d421fe-3e28-471b-8a95-293f0733d161", "ILLUSTRATIONS ALL/Calisthenics-Cardio-Plyo-Functional/Burpee  .jpg"),
    ("fa1778bc-774d-4a50-b770-d77d03acbd4c", "ILLUSTRATIONS ALL/Calisthenics-Cardio-Plyo-Functional/jumping jack  .jpg"),
    ("d9e75684-4be9-4071-9f40-3eec7c9fa7f4", "ILLUSTRATIONS ALL/Calisthenics-Cardio-Plyo-Functional/high knees.jpg"),
    ("4044ee27-2cb7-4c21-9b60-91c14d0731d2", "ILLUSTRATIONS ALL/Calisthenics-Cardio-Plyo-Functional/Kettlebell Swing.jpg"),
    ("e6e076cb-deea-487d-ac20-d827ab3ced9e", "ILLUSTRATIONS ALL/Legs/box jump  .jpg"),
    ("06ad8449-8a47-4ced-9e97-784775e28cf9", "ILLUSTRATIONS ALL/Powerlifting/Barbell Thruster.jpg"),
    ("4d1a878c-7f98-4b18-9615-c2d852563419", "ILLUSTRATIONS ALL/Calisthenics-Cardio-Plyo-Functional/Treadmill walk.jpg"),
    ("0350f1da-0008-4a34-ade0-ce7204a3405c", "ILLUSTRATIONS ALL/Calisthenics-Cardio-Plyo-Functional/Gym Elliptical Machine Fast Speed.jpg"),
    ("35094e6a-e38b-4f3b-a835-62c1b905ed45", "ILLUSTRATIONS ALL/Calisthenics-Cardio-Plyo-Functional/Gym Rowing Machine Fast Speed.jpg"),
]

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
OUT = os.path.join(REPO, "mobile", "flutter", "assets", "preview_exercises")
ENV = os.path.join(REPO, "backend", ".env")


def load_env():
    env = {}
    for line in open(ENV):
        line = line.strip()
        if "=" in line and not line.startswith("#"):
            k, _, v = line.partition("=")
            env[k.strip()] = v.strip().strip('"').strip("'")
    return env


def main():
    import boto3
    from PIL import Image

    env = load_env()
    s3 = boto3.client(
        "s3",
        aws_access_key_id=env["AWS_ACCESS_KEY_ID"],
        aws_secret_access_key=env["AWS_SECRET_ACCESS_KEY"],
        region_name=env.get("AWS_DEFAULT_REGION", "us-east-1"),
    )
    bucket = env["S3_BUCKET_NAME"]
    os.makedirs(OUT, exist_ok=True)
    total = 0
    for eid, key in ITEMS:
        data = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
        im = Image.open(io.BytesIO(data)).convert("RGB")
        im.thumbnail((256, 256))
        path = os.path.join(OUT, f"{eid}.jpg")
        im.save(path, "JPEG", quality=82)
        total += os.path.getsize(path)
    print(f"baked {len(ITEMS)} assets, {total // 1024} KB -> {OUT}")


if __name__ == "__main__":
    sys.exit(main())
