<?php
// ai_contract.php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  exit;
}

require_once "config.php";
require_once __DIR__ . "/vendor/autoload.php";
/* =========================
   Helpers
========================= */

function respond(array $payload, int $code = 200): void {
  http_response_code($code);
  echo json_encode($payload, JSON_UNESCAPED_UNICODE);
  exit;
}

function cleanup_text(string $t): string {
  $t = str_replace(["`", "**", "##", "#"], "", $t);
  $t = preg_replace("/\n{3,}/", "\n\n", $t);
  return trim($t);
}

function normalize_contract_type(string $t): string {
  $x = mb_strtolower(trim($t));

  if (in_array($x, ["services", "lease", "employment", "partnership", "nda"], true)) {
    return $x;
  }

  if (str_contains($x, "خدم")) return "services";
  if (str_contains($x, "ايجار") || str_contains($x, "إيجار") || str_contains($x, "اجار")) return "lease";
  if (str_contains($x, "عمل") || str_contains($x, "وظيف")) return "employment";
  if (str_contains($x, "شراك")) return "partnership";
  if ((str_contains($x, "عدم") && str_contains($x, "افشاء")) || str_contains($x, "إفشاء") || str_contains($x, "nda")) return "nda";

  return "";
}

function extract_user_texts(array $conversation): array {
  $userTexts = [];
  foreach ($conversation as $m) {
    if (!is_array($m)) continue;
    if (($m["role"] ?? "") === "user") {
      $t = trim((string)($m["content"] ?? ""));
      if ($t !== "") $userTexts[] = $t;
    }
  }
  return $userTexts;
}

function openai_extract_output_text(array $response): string {
  $text = "";
  if (isset($response["output_text"]) && is_string($response["output_text"])) {
    $text = $response["output_text"];
  } elseif (isset($response["output"]) && is_array($response["output"])) {
    foreach ($response["output"] as $o) {
      foreach (($o["content"] ?? []) as $c) {
        if (($c["type"] ?? "") === "output_text" && isset($c["text"])) {
          $text .= $c["text"];
        }
      }
    }
  }
  return trim($text);
}

function call_openai(array $data): array {
  $ch = curl_init("https://api.openai.com/v1/responses");
  curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
      "Authorization: Bearer " . OPENAI_API_KEY,
      "Content-Type: application/json"
    ],
    CURLOPT_POSTFIELDS => json_encode($data, JSON_UNESCAPED_UNICODE),

    // للتطوير فقط
    CURLOPT_SSL_VERIFYPEER => false,
    CURLOPT_SSL_VERIFYHOST => false,
  ]);

  $result = curl_exec($ch);
  $http   = curl_getinfo($ch, CURLINFO_HTTP_CODE);
  $err    = curl_error($ch);
  curl_close($ch);

  if ($result === false) {
    respond(["type" => "error", "message" => "cURL failed", "details" => $err], 500);
  }

  $decoded = json_decode($result, true);
  if ($http < 200 || $http >= 300) {
    $msg = $decoded["error"]["message"] ?? "OpenAI request failed";
    respond(["type" => "error", "message" => "OpenAI error", "details" => $msg], $http);
  }

  return is_array($decoded) ? $decoded : [];
}

function text_to_html_paragraphs(string $text): string {
  $parts = preg_split("/\n\s*\n/u", trim($text));
  $html = "";

  foreach ($parts as $p) {
    $p = nl2br(htmlspecialchars(trim($p), ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8'));
    if ($p !== "") {
      $html .= "<p>{$p}</p>";
    }
  }

  return $html;
}

function generate_pdf_file(string $contractText, string $contractLabel): array {
  $dir = __DIR__ . "/generated_contracts";
  if (!is_dir($dir)) {
    mkdir($dir, 0777, true);
  }

  $fileName = "contract_" . date("Ymd_His") . "_" . bin2hex(random_bytes(4)) . ".pdf";
  $filePath = $dir . "/" . $fileName;

  $htmlBody = text_to_html_paragraphs($contractText);

  $html = '
  <html lang="ar" dir="rtl">
    <head>
      <meta charset="UTF-8">
      <style>
        body {
          font-family: sans-serif;
          direction: rtl;
          text-align: right;
          font-size: 14px;
          line-height: 1.9;
        }
        h1 {
          text-align: center;
          font-size: 22px;
          margin-bottom: 10px;
        }
        .note {
          margin-top: 12px;
          margin-bottom: 20px;
          padding: 10px 12px;
          background: #fff8e1;
          border: 1px solid #f0d98a;
          border-radius: 6px;
          font-size: 12px;
        }
        p {
          margin: 0 0 10px 0;
        }
      </style>
    </head>
    <body>
      <h1>' . htmlspecialchars($contractLabel, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8') . '</h1>

      <div class="note">
        تنويه: هذه مسودة أولية للعقد وتحتاج إلى مراجعة من محامٍ مرخّص قبل الاعتماد أو التوقيع.
      </div>

      ' . $htmlBody . '
    </body>
  </html>';

  $mpdf = new \Mpdf\Mpdf([
    'mode' => 'utf-8',
    'format' => 'A4',
    'margin_top' => 15,
    'margin_bottom' => 15,
    'margin_left' => 12,
    'margin_right' => 12,
  ]);

  $mpdf->SetDirectionality('rtl');
  $mpdf->WriteHTML($html);
  $mpdf->Output($filePath, \Mpdf\Output\Destination::FILE);

  $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https" : "http";
  $host   = $_SERVER['HTTP_HOST'];
  $base   = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/\\');

  $fileUrl = $scheme . "://" . $host . $base . "/generated_contracts/" . $fileName;

  return [
    "file_name" => $fileName,
    "file_path" => $filePath,
    "file_url"  => $fileUrl,
  ];
}

/* =========================
   1) Read JSON
========================= */

$raw = file_get_contents("php://input");
$input = json_decode($raw, true);

if (!is_array($input)) {
  respond(["type" => "error", "message" => "JSON غير صالح"], 400);
}

$conversation = $input["conversation"] ?? [];
if (!is_array($conversation)) $conversation = [];

/* =========================
   2) First question options
========================= */

$contractTypeOptions = [
  ["id" => "services",    "label" => "عقد خدمات"],
  ["id" => "lease",       "label" => "عقد إيجار"],
  ["id" => "employment",  "label" => "عقد عمل"],
  ["id" => "partnership", "label" => "عقد شراكة"],
  ["id" => "nda",         "label" => "اتفاقية عدم إفشاء (NDA)"],
];

if (!is_array($conversation) || count($conversation) === 0) {
  respond([
    "type" => "question",
    "field" => "contract_type",
    "question" => "اختار نوع العقد:",
    "options" => $contractTypeOptions
  ]);
}

/* =========================
   3) Extract user messages
========================= */

$userTexts = extract_user_texts($conversation);
$userCount = count($userTexts);

if ($userCount === 0) {
  respond([
    "type" => "question",
    "field" => "contract_type",
    "question" => "اختار نوع العقد:",
    "options" => $contractTypeOptions
  ]);
}

/* =========================
   4) Determine contract type
========================= */

$contractTypeRaw = $userTexts[0] ?? "";
$contractType = normalize_contract_type($contractTypeRaw);

if ($contractType === "") {
  respond([
    "type" => "question",
    "field" => "contract_type",
    "question" => "ما فهمت نوع العقد. اختار من الخيارات:",
    "options" => $contractTypeOptions
  ]);
}

/* =========================
   5) Flows per contract type
========================= */

$flows = [
  "services" => [
    ["field" => "service_description", "q" => "وش الخدمات المطلوبة تحديدًا؟"],
    ["field" => "parties",             "q" => "من هم أطراف العقد؟ (اسم مقدم الخدمة + اسم العميل)"],
    ["field" => "duration",            "q" => "ما مدة العقد؟"],
    ["field" => "payment",             "q" => "ما المقابل المالي وطريقة الدفع؟"],
  ],
  "lease" => [
    ["field" => "property",            "q" => "وش بيانات العقار؟ (مدينة/حي + نوعه)"],
    ["field" => "parties",             "q" => "من هم أطراف العقد؟ (المؤجر + المستأجر)"],
    ["field" => "term",                "q" => "مدة الإيجار وتاريخ البداية؟"],
    ["field" => "rent",                "q" => "قيمة الإيجار وطريقة السداد؟"],
    ["field" => "deposit",             "q" => "هل فيه تأمين؟ وإذا نعم كم؟"],
  ],
  "employment" => [
    ["field" => "parties",             "q" => "اسم جهة العمل واسم الموظف؟"],
    ["field" => "job_title",           "q" => "المسمى الوظيفي؟"],
    ["field" => "salary",              "q" => "الراتب والمزايا (إن وجدت)؟"],
    ["field" => "start_date",          "q" => "تاريخ بداية العمل؟"],
    ["field" => "probation",           "q" => "هل فيه فترة تجربة؟ وإذا نعم كم مدتها؟"],
  ],
  "partnership" => [
    ["field" => "partners",            "q" => "أسماء الشركاء؟"],
    ["field" => "business",            "q" => "نوع النشاط؟"],
    ["field" => "shares",              "q" => "نِسب الشراكة لكل طرف؟"],
    ["field" => "capital",             "q" => "رأس المال وكيف يتم دفعه؟"],
    ["field" => "management",          "q" => "مين يدير الشراكة وكيف تُتخذ القرارات؟"],
  ],
  "nda" => [
    ["field" => "parties",             "q" => "أسماء الأطراف (مالك المعلومة + المستلم)؟"],
    ["field" => "scope",               "q" => "وش نوع المعلومات السرية؟ (وصف مختصر)"],
    ["field" => "purpose",             "q" => "وش هدف الإفصاح؟ (مثلاً: تفاوض/تقييم/شراكة)"],
    ["field" => "term",                "q" => "مدة السرية؟"],
  ],
];

$flow = $flows[$contractType] ?? null;
if (!is_array($flow)) {
  respond(["type" => "error", "message" => "نوع عقد غير مدعوم."], 400);
}

/* =========================
   6) Ask next question based on progress
========================= */

$answers = [];
$answeredCount = max(0, $userCount - 1);

for ($i = 0; $i < $answeredCount && $i < count($flow); $i++) {
  $answers[$flow[$i]["field"]] = $userTexts[$i + 1];
}

if ($answeredCount < count($flow)) {
  $next = $flow[$answeredCount];
  respond([
    "type" => "question",
    "field" => $next["field"],
    "question" => $next["q"],
    "contract_type" => $contractType
  ]);
}

/* =========================
   7) All collected -> draft contract with AI
========================= */

$typeLabelMap = [
  "services" => "عقد خدمات",
  "lease" => "عقد إيجار",
  "employment" => "عقد عمل",
  "partnership" => "عقد شراكة",
  "nda" => "اتفاقية عدم إفشاء (NDA)",
];

$label = $typeLabelMap[$contractType] ?? "عقد";

$systemPrompt = "أنت محامٍ محترف متخصص في صياغة العقود باللغة العربية الرسمية. "
  . "اكتب {$label} كاملًا ومنظمًا بعناوين وبنود مرقمة. "
  . "ممنوع استخدام رموز ماركداون مثل ** أو ## أو ` أو قوائم نجوم. "
  . "لا تخترع أسماء أو تواريخ أو أرقام غير مذكورة. "
  . "إذا نقصت معلومة جوهرية ضع مكانها: ____ دون طرح أسئلة. "
  . "اكتب بصياغة قانونية واضحة ومهنية.";

$userPrompt = "اكتب عقدًا بناءً على البيانات التالية:\n"
  . "- نوع العقد: {$label}\n"
  . "- تفاصيل مدخلة من المستخدم (JSON): " . json_encode($answers, JSON_UNESCAPED_UNICODE);

$data = [
  "model" => "gpt-4o-mini",
  "input" => [
    ["role" => "system", "content" => $systemPrompt],
    ["role" => "user", "content" => $userPrompt],
  ],
  "max_output_tokens" => 1200
];

$response = call_openai($data);
$text = cleanup_text(openai_extract_output_text($response));

if ($text === "") {
  respond([
    "type" => "error",
    "message" => "تعذر إنشاء العقد، حاول مرة أخرى."
  ], 500);
}

$pdfInfo = generate_pdf_file($text, $label);

respond([
  "type" => "contract",
  "text" => $text,
  "pdf_url" => $pdfInfo["file_url"],
  "contract_type" => $contractType
]);