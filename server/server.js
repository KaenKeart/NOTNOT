const express = require("express");
const bodyParser = require("body-parser");
const mysql = require("mysql");
const crypto = require("crypto");
const cors = require("cors");
const multer = require("multer");
const fetch = require("node-fetch"); // ใช้ fetch แทน axios
const fs = require("fs");
const path = require("path");
const FormData = require("form-data");

const app = express();
const port = 3000;

app.use(cors({ origin: "*" }));
app.use(bodyParser.json());

// ตั้งค่าการอัปโหลดไฟล์โดยใช้ multer
const upload = multer({ dest: "uploads/" });

// ตั้งค่าการเชื่อมต่อฐานข้อมูล MySQL
const db = mysql.createConnection({
  host: "localhost",
  user: "root",
  password: "",
  database: "acne",
});

db.connect((err) => {
  if (err) {
    console.error("Error connecting to MySQL:", err);
    process.exit(1);
  }
  console.log("MySQL connected...");
});

// ฟังก์ชัน hash MD5 สำหรับการเข้ารหัสรหัสผ่าน
function hashMD5(password) {
  return crypto.createHash("md5").update(password).digest("hex");
}

// Endpoint สำหรับลงทะเบียน
app.post("/signin", (req, res) => {
  const { username, password, email } = req.body;

  if (!username || !password || !email) {
    return res
      .status(400)
      .send({ status: "error", message: "Missing required fields" });
  }

  const hashedPassword = hashMD5(password);

  const query =
    "INSERT INTO users (username, password, email) VALUES (?, ?, ?)";
  db.query(query, [username, hashedPassword, email], (err, result) => {
    if (err) {
      console.error("Error during user registration:", err);
      return res.status(500).send({
        status: "error",
        message: "User registration failed",
        error: err.message,
      });
    }
    res.send({ status: "success", message: "User registered successfully" });
  });
});

// Endpoint สำหรับเข้าสู่ระบบ
app.post("/login", (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res
      .status(400)
      .send({ status: "error", message: "Missing username or password" });
  }

  const hashedPassword = hashMD5(password);

  const query = "SELECT * FROM users WHERE username = ?";
  db.query(query, [username], (err, results) => {
    if (err) {
      console.error("Error during user login:", err);
      return res.status(500).send({
        status: "error",
        message: "An error occurred during login",
        error: err.message,
      });
    }
    if (results.length === 0) {
      return res
        .status(404)
        .send({ status: "error", message: "User not found" });
    }

    const user = results[0];
    if (user.password === hashedPassword) {
      res.send({ status: "success", message: "Login successful" });
    } else {
      res.status(401).send({ status: "error", message: "Invalid password" });
    }
  });
});

// ฟังก์ชันส่งภาพไปยัง Flask API
async function sendImageForPrediction(imagePath) {
  const formData = new FormData();
  formData.append("image", fs.createReadStream(imagePath));

  try {
    const response = await fetch("http://127.0.0.1:5001/predict", {
      // เปลี่ยนที่อยู่เป็น 5001
      method: "POST",
      body: formData,
      headers: formData.getHeaders(), // เพิ่ม headers ของ formData
    });

    if (!response.ok) {
      throw new Error(`Error in Flask API: ${response.statusText}`);
    }

    const result = await response.json();
    return result.predictions;
  } catch (error) {
    console.error("Error sending image to Flask API:", error);
    throw error;
  }
}

// Endpoint สำหรับการอัปโหลดและทำนายภาพ
app.post("/upload", upload.single("image"), async (req, res) => {
  if (!req.file) {
    return res
      .status(400)
      .send({ status: "error", message: "No file uploaded" });
  }

  const imagePath = path.join(__dirname, req.file.path);

  try {
    const predictionResults = await sendImageForPrediction(imagePath);
    const predictionClass = predictionResults[0].class;

    const query = `INSERT INTO image (image_name, prediction_result) VALUES (?, ?)`;
    db.query(query, [req.file.filename, predictionClass], (err, result) => {
      if (err) {
        console.error("Error inserting into database:", err);
        return res
          .status(500)
          .send({
            status: "error",
            message: "Error saving image data to database",
          });
      }
      console.log("Image data inserted into database");
    });

    // ตรวจสอบว่ามีไฟล์อยู่ก่อนทำการลบ
    if (fs.existsSync(imagePath)) {
      fs.unlinkSync(imagePath); // ลบไฟล์หลังจากใช้งานเสร็จ
    } else {
      console.warn(`File not found: ${imagePath}`);
    }

    return res.send({
      status: "success",
      message: "Prediction completed",
      predictions: predictionResults,
    });
  } catch (error) {
    console.error("Error predicting image:", error);
    return res.status(500).send({
      status: "error",
      message: "Error predicting image",
      error: error.message,
    });
  }
});

app.listen(port, "0.0.0.0", () => {
  console.log(`Server running on port ${port}`);
});
