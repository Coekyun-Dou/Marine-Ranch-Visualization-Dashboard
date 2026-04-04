import cv2
import numpy as np
import os
import json
import argparse
from ultralytics import YOLO


class YOLOv8Detector:
    def __init__(self, model_path, conf=0.5, iou=0.5):
        self.model = YOLO(model_path)
        self.model.fuse()
        self.conf = conf
        self.iou = iou

        np.random.seed(42)
        self.COLORS = np.random.uniform(0, 255, size=(80, 3))

    def detect(self, img_source):
        results = self.model.predict(
            source=img_source,
            imgsz=640,
            conf=self.conf,
            iou=self.iou,
            device='cpu',
            verbose=False
        )
        return self._parse_results(img_source.copy(), results[0])

    def _parse_results(self, img, results):
        boxes = results.boxes.cpu().numpy()

        class_names = list(results.names.values())
        statistic_dic = {name: 0 for name in class_names}
        detections = []

        for box in boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            cls_id = int(box.cls[0])
            conf = float(box.conf[0])
            class_name = results.names[cls_id]

            statistic_dic[class_name] += 1
            detections.append({
                "className": class_name,
                "confidence": round(conf, 4),
                "bbox": [x1, y1, x2, y2]
            })

            color = self.COLORS[cls_id % len(self.COLORS)].tolist()
            label = f"{class_name} {conf:.2f}"

            cv2.rectangle(img, (x1, y1), (x2, y2), color, thickness=3)
            (text_w, text_h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.8, 2)
            cv2.rectangle(img, (x1, y1 - text_h - 10), (x1 + text_w, y1 - 10), color, -1)
            cv2.putText(img, label, (x1, y1 - 15), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)

        statistics = {k: v for k, v in statistic_dic.items() if v > 0}
        total_count = int(sum(statistics.values()))

        return {
            "image": img,
            "statistics": statistics,
            "totalCount": total_count,
            "detections": detections
        }


def run_single_image(detector, source, output_dir=None, save_annotated=False):
    img = cv2.imread(source)
    if img is None:
        raise FileNotFoundError(f"无法读取图片: {source}")

    result = detector.detect(img)
    output_image_path = None

    if save_annotated:
        os.makedirs(output_dir or "results", exist_ok=True)
        filename = os.path.basename(source)
        output_image_path = os.path.join(output_dir or "results", f"detected_{filename}")
        cv2.imwrite(output_image_path, result["image"])

    return {
        "source": source,
        "type": "image",
        "statistics": result["statistics"],
        "totalCount": result["totalCount"],
        "detections": result["detections"],
        "annotatedImage": output_image_path,
        "outputVideo": None
    }


def run_video(detector, source, output_dir=None, save_annotated=False):
    cap = cv2.VideoCapture(source)
    if not cap.isOpened():
        raise FileNotFoundError(f"无法读取视频: {source}")

    frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)) or 1280
    frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)) or 720
    fps = cap.get(cv2.CAP_PROP_FPS)
    if not fps or fps <= 0:
        fps = 25

    os.makedirs(output_dir or "results", exist_ok=True)
    filename = os.path.basename(source)
    output_video_path = os.path.join(output_dir or "results", f"detected_{filename}")

    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_video_path, fourcc, fps, (frame_width, frame_height))

    total_frames = 0
    aggregate_stats = {}
    max_count = 0
    sample_detections = []

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        total_frames += 1
        result = detector.detect(frame)

        for cls, count in result["statistics"].items():
            aggregate_stats[cls] = aggregate_stats.get(cls, 0) + count

        max_count = max(max_count, result["totalCount"])

        if not sample_detections and result["detections"]:
            sample_detections = result["detections"][:20]

        if save_annotated:
            out.write(result["image"])

    cap.release()
    out.release()

    avg_stats = {k: int(round(v / total_frames)) for k, v in aggregate_stats.items()} if total_frames > 0 else {}

    return {
        "source": source,
        "type": "video",
        "frameCount": total_frames,
        "statistics": avg_stats,
        "totalCount": max_count,
        "detections": sample_detections,
        "annotatedImage": None,
        "outputVideo": output_video_path if save_annotated else None
    }


def is_video_file(source):
    ext = os.path.splitext(source)[1].lower()
    return ext in ['.mp4', '.avi', '.mov', '.mkv', '.wmv', '.flv']


def parse_args():
    parser = argparse.ArgumentParser(description="YOLOv8 鱼类检测")
    parser.add_argument("--model", default="best.pt", help="模型路径")
    parser.add_argument("--source", default="123.png", help="输入图片或视频路径")
    parser.add_argument("--conf", type=float, default=0.5, help="置信度阈值")
    parser.add_argument("--iou", type=float, default=0.5, help="NMS IoU阈值")
    parser.add_argument("--json", action="store_true", help="仅输出JSON结果")
    parser.add_argument("--save", action="store_true", help="是否保存标注结果")
    parser.add_argument("--output", default="results", help="保存目录")
    return parser.parse_args()


def main():
    args = parse_args()

    detector = YOLOv8Detector(args.model, conf=args.conf, iou=args.iou)

    if is_video_file(args.source):
        result = run_video(detector, args.source, output_dir=args.output, save_annotated=args.save)
    else:
        result = run_single_image(detector, args.source, output_dir=args.output, save_annotated=args.save)

    if args.json:
        print(json.dumps({"success": True, "data": result}, ensure_ascii=False))
        return

    print("[检测统计]")
    if result["totalCount"] == 0:
        print("  未检测到目标")
    else:
        for cls, count in result["statistics"].items():
            print(f"  {cls}: {count}个")

    if result.get("annotatedImage"):
        print(f"图片结果已保存至: {result['annotatedImage']}")
    if result.get("outputVideo"):
        print(f"视频结果已保存至: {result['outputVideo']}")


if __name__ == "__main__":
    main()
