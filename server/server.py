from flask import Flask, request, jsonify
from keras.models import load_model
from keras.preprocessing.image import load_img, img_to_array
import numpy as np
from PIL import Image

app = Flask(__name__)

# โหลดโมเดล
model = load_model(
    "/Users/nathakornphikromsuk/Downloads/Acne-main 2/server/models/my_model.keras"
)
print("Model loaded successfully.")

# กำหนดชื่อระดับการทำนาย
class_names = ["ไม่มีสิว", "สิวระดับต่ำ", "สิวระดับปานกลาง", "สิวระดับสูง"]


@app.route("/predict", methods=["POST"])
def predict():
    if "image" not in request.files:
        print("No image provided")  # ข้อความแสดงข้อผิดพลาด
        return jsonify({"error": "No image provided"}), 400

    file = request.files["image"]

    # ตรวจสอบนามสกุลไฟล์
    if not file or not file.filename.endswith((".jpg", ".jpeg", ".png")):
        print("Invalid image format")  # ข้อความแสดงข้อผิดพลาด
        return (
            jsonify(
                {
                    "error": "Invalid image format. Please upload a .jpg, .jpeg, or .png file."
                }
            ),
            400,
        )

    try:
        # โหลดภาพ
        img = Image.open(file.stream)  # ใช้ PIL เพื่อเปิดไฟล์ภาพ
        img = img.resize((224, 224))  # ปรับขนาดให้เข้ากับขนาดของโมเดลที่ต้องการ
        img_array = (
            img_to_array(img) / 255.0
        )  # แปลงภาพเป็นอาร์เรย์และทำให้เป็นค่าระหว่าง 0 ถึง 1
        img_array = np.expand_dims(img_array, axis=0)  # เพิ่มมิติสำหรับ batch

        # ทำนาย
        prediction = model.predict(img_array)

        # แสดงผลลัพธ์การทำนาย
        predicted_class = np.argmax(prediction, axis=1)[0]  # ระบุคลาสที่ทำนาย
        response = {
            "predictions": prediction[0].tolist(),  # ส่งกลับเป็น JSON
            "predicted_class": class_names[predicted_class],  # ชื่อระดับการทำนาย
            "message": "Prediction successful",
            "accuracy": float(np.max(prediction)) * 100,  # ความแม่นยำ
        }
        return jsonify(response), 200

    except Exception as e:
        print(f"Error during prediction: {e}")  # ข้อความแสดงข้อผิดพลาด
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
