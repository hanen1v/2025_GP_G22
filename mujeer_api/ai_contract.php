<?php
// ai_contract.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  exit;
}

require_once "config.php"; // يحتوي OPENAI_API_KEY

// ===== 1) قراءة JSON من Flutter =====
$raw = file_get_contents("php://input");
$input = json_decode($raw, true);

if (json_last_error() !== JSON_ERROR_NONE) {
  http_response_code(400);
  echo json_encode([
    "reply" => "خطأ: صيغة البيانات المرسلة غير صحيحة (JSON).",
    "debug" => json_last_error_msg()
  ], JSON_UNESCAPED_UNICODE);
  exit;
}

$userMessage = trim($input["message"] ?? "");
if ($userMessage === "") {
  http_response_code(400);
  echo json_encode([
    "reply" => "اكتبي طلبك أولًا 🙂"
  ], JSON_UNESCAPED_UNICODE);
  exit;
}

// ===== 2) تجهيز طلب OpenAI =====
// ملاحظة: استخدمت gpt-4o-mini لتقليل التكلفة
$data = [
  "model" => "gpt-4o-mini",
  "input" => [
    [
      "role" => "system",
      "content" =>
        "أنت مساعد قانوني ذكي متخصص في صياغة العقود باللغة العربية الفصحى الرسمية. " .
        "إذا كانت المعلومات ناقصة اسأل أسئلة توضيحية قبل كتابة العقد. " .
        "لا تخترع أسماء أو أرقام أو تواريخ. عند اكتمال البيانات اكتب عقدًا منظمًا بعناوين وبنود مرقمة."
    ],
    [
      "role" => "user",
      "content" => $userMessage
    ]
  ],
  // تقليل طول الرد لتقليل التكلفة (اختياري)
  "max_output_tokens" => 600
];

// ===== 3) إرسال الطلب =====
$ch = curl_init("https://api.openai.com/v1/responses");
curl_setopt_array($ch, [
  CURLOPT_POST => true,
  CURLOPT_RETURNTRANSFER => true,
  CURLOPT_HTTPHEADER => [
    "Authorization: Bearer " . OPENAI_API_KEY,
    "Content-Type: application/json"
  ],
  CURLOPT_POSTFIELDS => json_encode($data, JSON_UNESCAPED_UNICODE),

  // الحل السريع لمشكلة SSL على MAMP (للتطوير فقط)
  CURLOPT_SSL_VERIFYPEER => false,
  CURLOPT_SSL_VERIFYHOST => false,
]);

$result = curl_exec($ch);
$http   = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$err    = curl_error($ch);
curl_close($ch);

if ($result === false) {
  http_response_code(500);
  echo json_encode([
    "reply" => "خطأ اتصال بالسيرفر (cURL).",
    "debug" => $err
  ], JSON_UNESCAPED_UNICODE);
  exit;
}

$response = json_decode($result, true);

// ===== 4) لو OpenAI رجع خطأ =====
if ($http < 200 || $http >= 300) {
  $msg = $response["error"]["message"] ?? "OpenAI request failed";
  http_response_code($http);
  echo json_encode([
    "reply" => "خطأ من OpenAI: " . $msg
  ], JSON_UNESCAPED_UNICODE);
  exit;
}

// ===== 5) استخراج النص بشكل آمن من Responses API =====
$reply = "";

// بعض الاستجابات فيها output_text مباشرة
if (isset($response["output_text"]) && is_string($response["output_text"])) {
  $reply = $response["output_text"];
}

// أو داخل output[].content[] حيث type = output_text
if ($reply === "" && isset($response["output"]) && is_array($response["output"])) {
  foreach ($response["output"] as $item) {
    if (!isset($item["content"]) || !is_array($item["content"])) continue;

    foreach ($item["content"] as $content) {
      if (($content["type"] ?? "") === "output_text" && isset($content["text"])) {
        $reply .= $content["text"];
      }
    }
  }
}

$reply = trim($reply);
if ($reply === "") {
  $reply = "تعذر استخراج الرد من الذكاء الاصطناعي.";
}

// ===== 6) الرد النهائي للتطبيق =====
echo json_encode([
  "reply" => $reply
], JSON_UNESCAPED_UNICODE);
