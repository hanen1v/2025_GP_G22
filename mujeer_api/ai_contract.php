<?php
// ai_contract.php

// ✅ منع PHP من طباعة notices/warnings قبل JSON
error_reporting(0);
ini_set('display_errors', '0');

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
  if (in_array($x, ["services", "lease", "employment", "partnership", "nda"], true)) return $x;
  if (str_contains($x, "خدم") || str_contains($x, "مقاول"))                            return "services";
  if (str_contains($x, "ايجار") || str_contains($x, "إيجار") || str_contains($x, "اجار")) return "lease";
  if (str_contains($x, "عمل")  || str_contains($x, "وظيف")  || str_contains($x, "توظيف")) return "employment";
  if (str_contains($x, "شراك") || str_contains($x, "شريك"))                             return "partnership";
  if ((str_contains($x, "عدم") && str_contains($x, "افشاء")) ||
       str_contains($x, "إفشاء") || str_contains($x, "سري") || str_contains($x, "nda")) return "nda";
  return "";
}

function extract_user_texts(array $conversation): array {
  $out = [];
  foreach ($conversation as $m) {
    if (!is_array($m)) continue;
    if (($m["role"] ?? "") === "user") {
      $t = trim((string)($m["content"] ?? ""));
      if ($t !== "") $out[] = $t;
    }
  }
  return $out;
}

function openai_extract_output_text(array $response): string {
  return trim($response["choices"][0]["message"]["content"] ?? "");
}

function call_openai(array $data): array {
  $ch = curl_init("https://api.openai.com/v1/chat/completions");
  curl_setopt_array($ch, [
    CURLOPT_POST           => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER     => [
      "Authorization: Bearer " . OPENAI_API_KEY,
      "Content-Type: application/json"
    ],
    CURLOPT_POSTFIELDS     => json_encode($data, JSON_UNESCAPED_UNICODE),
    CURLOPT_SSL_VERIFYPEER => false, // للتطوير فقط
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

/* =========================
   التحقق الذكي بـ GPT
   يُرسل السؤال + الإجابة لـ gpt-4o
   يرجع "" إذا صح، أو رسالة خطأ عربية
========================= */
function validate_answer_with_gpt(string $fieldLabel, string $question, string $answer): string {

  $v = trim($answer);

  // تحقق سريع قبل استدعاء API
  if (mb_strlen($v) < 2) {
    return "الإجابة قصيرة جداً، يرجى التوضيح أكثر.";
  }
  if (preg_match('/^(.)\1{3,}$/u', $v)) {
    return "يرجى إدخال إجابة صحيحة ومفهومة.";
  }

  $prompt =
    "أنت مساعد قانوني تتحقق من إجابة المستخدم لصياغة عقد.\n\n"
    . "الحقل: {$fieldLabel}\n"
    . "السؤال: {$question}\n"
    . "إجابة المستخدم: {$answer}\n\n"
    . "قواعد التحقق — كن متساهلاً:\n"
    . "- اقبل أي إجابة فيها معلومة مفيدة حتى لو مختصرة\n"
    . "- اقبل الأسماء حتى لو ناقصة (مثل: أحمد، شركة النور)\n"
    . "- اقبل المسميات الوظيفية المختصرة (مثل: مطور، محاسب، مدير، مهندس)\n"
    . "- اقبل المدد البسيطة (مثل: سنة، شهرين، 90 يوم، غير محدد)\n"
    . "- اقبل الإجابات الجزئية إذا كانت ذات معنى\n"
    . "- ارفض فقط الإجابات العشوائية الواضحة: (مدري، لا أعرف، ههه، ؟؟؟، كلام عشوائي، حروف بدون معنى)\n"
    . "- للحقول المالية: ارفض فقط إذا لم يذكر أي رقم أو مبلغ\n\n"
    . "إذا الإجابة مقبولة أجب فقط بكلمة: VALID\n"
    . "إذا مرفوضة أجب برسالة قصيرة بالعربية (جملة واحدة فقط) توضح ما ينقص.";

  $data = [
    "model"    => "gpt-4o",
    "messages" => [["role" => "user", "content" => $prompt]],
    "max_tokens" => 150,
  ];

  $response = call_openai($data);
  $result   = trim(openai_extract_output_text($response));

  return ($result === "VALID") ? "" : $result;
}

/* =========================
   توليد PDF
========================= */
function format_contract_html(string $text): string {
  $lines  = explode("\n", trim($text));
  $html   = "";
  $inList = false;

  foreach ($lines as $line) {
    $line = trim($line);
    if ($line === "") {
      if ($inList) { $html .= "</ul>"; $inList = false; }
      continue;
    }
    $escaped = htmlspecialchars($line, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');

    if (mb_strlen($line) <= 40 && str_ends_with($line, ':')) {
      if ($inList) { $html .= "</ul>"; $inList = false; }
      $html .= "<h2>{$escaped}</h2>";
    } elseif (preg_match('/^[\d]+[\.\d]*[\.\-\)]\s/u', $line)) {
      if (!$inList) { $html .= "<ul>"; $inList = true; }
      $html .= "<li>{$escaped}</li>";
    } else {
      if ($inList) { $html .= "</ul>"; $inList = false; }
      $html .= "<p>{$escaped}</p>";
    }
  }
  if ($inList) $html .= "</ul>";
  return $html;
}

function generate_pdf_file(string $contractText, string $contractLabel): array {
  $dir = __DIR__ . "/generated_contracts";
  if (!is_dir($dir)) mkdir($dir, 0777, true);

  // ✅ مجلد مؤقت لـ mPDF — يحل MpdfException
  $tmpDir = __DIR__ . "/mpdf_tmp";
  if (!is_dir($tmpDir)) mkdir($tmpDir, 0777, true);

  $fileName  = "contract_" . date("Ymd_His") . "_" . bin2hex(random_bytes(4)) . ".pdf";
  $filePath  = $dir . "/" . $fileName;
  $body      = format_contract_html($contractText);
  $safeLabel = htmlspecialchars($contractLabel, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');

  $html = <<<HTML
  <!DOCTYPE html>
  <html lang="ar" dir="rtl">
  <head><meta charset="UTF-8">
  <style>
    @page { margin: 22mm 20mm 25mm 20mm; }
    body  { font-family: 'Arial','Tahoma',sans-serif; font-size: 13px; line-height: 2; color: #1a1a1a; direction: rtl; text-align: right; }
    .header-bar { border-top: 5px solid #0B5345; border-bottom: 2px solid #0B5345; padding: 10px 0 8px; margin-bottom: 18px; text-align: center; }
    .header-bar .doc-title { font-size: 22px; font-weight: bold; color: #0B5345; }
    .header-bar .doc-sub   { font-size: 11px; color: #555; margin-top: 3px; }
    .notice { background:#fffbea; border:1px solid #e6c619; border-right:4px solid #e6c619; border-radius:4px; padding:7px 12px; font-size:11px; color:#7a6000; margin-bottom:20px; }
    h2  { font-size:14px; font-weight:bold; color:#0B5345; border-bottom:1px solid #c8ddd9; padding-bottom:3px; margin:20px 0 8px; }
    p   { margin:0 0 8px; text-align:justify; }
    ul  { list-style:none; padding:0; margin:0 0 10px; }
    ul li { padding:4px 14px 4px 0; border-bottom:1px dotted #dde8e6; text-align:justify; }
    ul li:last-child { border-bottom:none; }
    .footer { position:fixed; bottom:0; left:0; right:0; border-top:1px solid #c8ddd9; font-size:10px; color:#888; text-align:center; padding:4px 0; }
  </style>
  </head>
  <body>
    <div class="footer">مسودة أولية — غير معتمدة للتوقيع قبل مراجعة محامٍ مرخّص</div>
    <div class="header-bar">
      <div class="doc-title">{$safeLabel}</div>
      <div class="doc-sub">المملكة العربية السعودية — وفق أنظمة وزارة العدل</div>
    </div>
    <div class="notice">⚠ تنويه: هذه مسودة أولية للعقد وتحتاج إلى مراجعة من محامٍ مرخّص قبل الاعتماد أو التوقيع.</div>
    {$body}
  </body>
  </html>
  HTML;

  // ✅ tempDir يحل MpdfException
  $mpdf = new \Mpdf\Mpdf([
    'mode'          => 'utf-8',
    'format'        => 'A4',
    'margin_top'    => 10,
    'margin_bottom' => 18,
    'margin_left'   => 15,
    'margin_right'  => 15,
    'tempDir'       => $tmpDir,
  ]);
  $mpdf->SetDirectionality('rtl');
  $mpdf->WriteHTML($html);
  $mpdf->Output($filePath, \Mpdf\Output\Destination::FILE);

  $scheme  = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https" : "http";
  $host    = $_SERVER['HTTP_HOST'];
  $base    = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/\\');
  $fileUrl = $scheme . "://" . $host . $base . "/generated_contracts/" . $fileName;

  return ["file_name" => $fileName, "file_path" => $filePath, "file_url" => $fileUrl];
}

/* =========================
   1) قراءة JSON
========================= */
$raw   = file_get_contents("php://input");
$input = json_decode($raw, true);

if (!is_array($input)) {
  respond(["type" => "error", "message" => "JSON غير صالح"], 400);
}

$conversation = $input["conversation"] ?? [];
if (!is_array($conversation)) $conversation = [];

/* =========================
   2) خيارات نوع العقد
========================= */
$contractTypeOptions = [
  ["id" => "employment",  "label" => "عقد عمل"],
  ["id" => "lease",       "label" => "عقد إيجار"],
  ["id" => "services",    "label" => "عقد خدمات"],
  ["id" => "partnership", "label" => "عقد شراكة"],
  ["id" => "nda",         "label" => "اتفاقية عدم إفشاء (NDA)"],
];

if (count($conversation) === 0) {
  respond([
    "type"     => "question",
    "field"    => "contract_type",
    "question" => "أهلاً! أنا مساعد صياغة العقود.\nاختر نوع العقد الذي تحتاجه:",
    "options"  => $contractTypeOptions,
  ]);
}

/* =========================
   3) استخراج رسائل المستخدم
========================= */
$userTexts = extract_user_texts($conversation);
$userCount = count($userTexts);

if ($userCount === 0) {
  respond([
    "type"     => "question",
    "field"    => "contract_type",
    "question" => "اختر نوع العقد الذي تحتاجه:",
    "options"  => $contractTypeOptions,
  ]);
}

/* =========================
   4) تحديد نوع العقد
========================= */
$contractTypeRaw = $userTexts[0] ?? "";
$contractType    = normalize_contract_type($contractTypeRaw);

if ($contractType === "") {
  respond([
    "type"     => "question",
    "field"    => "contract_type",
    "question" => "لم أتمكن من تحديد نوع العقد. اختر من الخيارات التالية:",
    "options"  => $contractTypeOptions,
  ]);
}

/* =========================
   5) أسئلة كل نوع عقد
   كل سؤال فيه: field + label (للتحقق) + q (للعرض)
========================= */
$flows = [

  "employment" => [
    ["field" => "parties",    "label" => "أطراف العقد",            "q" => "ما اسم صاحب العمل (الشركة أو الشخص) واسم الموظف بالكامل؟\nمثال: شركة الأفق للتقنية — أحمد محمد العتيبي"],
    ["field" => "job_title",  "label" => "المسمى الوظيفي والمهام", "q" => "ما المسمى الوظيفي ووصف مهام الوظيفة بشكل مختصر؟\nمثال: مطوّر برمجيات أول — مسؤول عن تطوير تطبيقات الجوال"],
    ["field" => "salary",     "label" => "الراتب والمزايا",         "q" => "ما الراتب الشهري؟ وهل توجد بدلات أو مزايا إضافية؟\nمثال: 12,000 ريال + بدل سكن 2,000 ريال + تأمين صحي"],
    ["field" => "start_date", "label" => "تاريخ البداية ومدة العقد","q" => "ما تاريخ بداية العمل؟ وهل العقد محدد المدة أم غير محدد؟\nمثال: 1 محرم 1447هـ — عقد محدد المدة لسنة قابل للتجديد"],
    ["field" => "probation",  "label" => "فترة التجربة وساعات العمل","q" => "هل توجد فترة تجربة؟ وما ساعات العمل وأيام الإجازة الأسبوعية؟\nمثال: فترة تجربة 90 يومًا، 8 ساعات يوميًا، إجازة الجمعة والسبت"],
  ],

  "lease" => [
    ["field" => "property", "label" => "بيانات العقار",        "q" => "ما بيانات العقار؟ نوعه، موقعه (مدينة وحي)، ومساحته.\nمثال: شقة سكنية في حي النزهة بالرياض، 120 م²، الدور الثاني"],
    ["field" => "parties",  "label" => "أطراف عقد الإيجار",   "q" => "ما اسم المؤجر (صاحب العقار) واسم المستأجر بالكامل؟\nمثال: المؤجر: فهد الغامدي — المستأجر: محمد الزهراني"],
    ["field" => "term",     "label" => "مدة الإيجار",          "q" => "ما مدة الإيجار وتاريخ بداية العقد؟\nمثال: سنة كاملة تبدأ من 1 محرم 1447هـ"],
    ["field" => "rent",     "label" => "قيمة الإيجار",         "q" => "ما قيمة الإيجار وكيف يتم السداد؟\nمثال: 30,000 ريال سنويًا بأربعة شيكات ربع سنوية"],
    ["field" => "deposit",  "label" => "مبلغ التأمين",         "q" => "هل يوجد تأمين؟ كم قيمته وما شروط إعادته؟\nمثال: تأمين 3,000 ريال يُعاد عند انتهاء العقد مع سلامة الوحدة"],
  ],

  "services" => [
    ["field" => "service_description", "label" => "وصف الخدمة أو المشروع", "q" => "صف الخدمة أو المشروع المطلوب بوضوح.\nمثال: تصميم وتطوير موقع إلكتروني متجاوب مع الجوال بلوحة تحكم"],
    ["field" => "parties",             "label" => "أطراف عقد الخدمات",     "q" => "ما اسم مقدم الخدمة واسم العميل؟\nمثال: مؤسسة تقنيات المستقبل — شركة النور التجارية"],
    ["field" => "duration",            "label" => "مدة تنفيذ الخدمة",      "q" => "ما المدة الزمنية للتنفيذ وتاريخ التسليم؟\nمثال: 45 يوم عمل، تسليم نهائي مارس 2025"],
    ["field" => "payment",             "label" => "المقابل المالي وطريقة الدفع", "q" => "ما المبلغ الإجمالي وطريقة الدفع؟\nمثال: 15,000 ريال — 30% عند التوقيع، 70% عند التسليم النهائي"],
  ],

  "partnership" => [
    ["field" => "partners",   "label" => "أسماء الشركاء وهويتهم",  "q" => "ما أسماء جميع الشركاء بالكامل وهويتهم؟\nمثال: خالد السبيعي (شخص طبيعي) — مؤسسة الريادة للتجارة"],
    ["field" => "business",   "label" => "طبيعة النشاط ومكانه",    "q" => "ما طبيعة النشاط التجاري ومكان مزاولته؟\nمثال: استيراد وتوزيع مواد غذائية — مقر الشراكة في جدة"],
    ["field" => "shares",     "label" => "نسب الشراكة في الأرباح", "q" => "ما نسبة كل شريك في الأرباح والخسائر؟\nمثال: الشريك الأول 60% — الشريك الثاني 40%"],
    ["field" => "capital",    "label" => "رأس المال وطريقة الإيداع","q" => "ما رأس المال الإجمالي وكيف يُوزَّع ويُودَع؟\nمثال: 500,000 ريال — 300,000 من الأول، 200,000 من الثاني"],
    ["field" => "management", "label" => "إدارة الشراكة واتخاذ القرار","q" => "من يدير الشراكة وكيف تُتخذ القرارات؟\nمثال: الشريك الأول للعمليات اليومية، الكبرى بالإجماع"],
  ],

  "nda" => [
    ["field" => "parties", "label" => "أطراف اتفاقية السرية",   "q" => "ما اسم المالك للمعلومات السرية واسم المستلم؟\nمثال: شركة إبداع للتقنية — محمد الشهري (مستشار خارجي)"],
    ["field" => "scope",   "label" => "نوع المعلومات السرية",   "q" => "ما نوع المعلومات السرية التي يشملها الاتفاق؟\nمثال: بيانات العملاء، الخوارزميات، التقارير المالية"],
    ["field" => "purpose", "label" => "الغرض من الإفصاح",       "q" => "ما الغرض من الاطلاع على هذه المعلومات؟\nمثال: تقييم التعاون في تطوير نظام محاسبي مشترك"],
    ["field" => "term",    "label" => "مدة سريان الاتفاقية",    "q" => "ما مدة الاتفاقية والتزام السرية بعد انتهائها؟\nمثال: سنتان، مع التزام سرية 3 سنوات بعد الانتهاء"],
  ],

];

$flow = $flows[$contractType] ?? null;
if (!is_array($flow)) {
  respond(["type" => "error", "message" => "نوع عقد غير مدعوم."], 400);
}

$total = count($flow);

/* =========================
   6) سؤال تلو الآخر + تحقق GPT من آخر إجابة
========================= */

// userTexts[0] = نوع العقد، userTexts[1..n] = إجابات الأسئلة
$answeredCount = max(0, $userCount - 1);

// ✅ تحقق من آخر إجابة قبل الانتقال للسؤال التالي
if ($answeredCount > 0 && $answeredCount <= $total) {
  $lastIndex = $answeredCount - 1;
  $lastField = $flow[$lastIndex];
  $lastValue = $userTexts[$answeredCount] ?? "";

  $error = validate_answer_with_gpt(
    $lastField["label"],
    $lastField["q"],
    $lastValue
  );

  if ($error !== "") {
    // أعد نفس السؤال مع رسالة الخطأ
    respond([
      "type"          => "question",
      "field"         => $lastField["field"],
      "question"      => "⚠️ {$error}\n\n({$answeredCount}/{$total}) " . $lastField["q"],
      "contract_type" => $contractType,
      "retry"         => true,
    ]);
  }
}

// بناء مصفوفة الإجابات الصحيحة
$answers = [];
for ($i = 0; $i < $answeredCount && $i < $total; $i++) {
  $answers[$flow[$i]["field"]] = $userTexts[$i + 1];
}

// هل بقي أسئلة؟
if ($answeredCount < $total) {
  $next = $flow[$answeredCount];
  $step = $answeredCount + 1;
  respond([
    "type"          => "question",
    "field"         => $next["field"],
    "question"      => "({$step}/{$total}) " . $next["q"],
    "contract_type" => $contractType,
  ]);
}

/* =========================
   7) كل الإجابات صحيحة → ولّد العقد
========================= */
$typeLabelMap = [
  "services"    => "عقد خدمات",
  "lease"       => "عقد إيجار",
  "employment"  => "عقد عمل",
  "partnership" => "عقد شراكة",
  "nda"         => "اتفاقية عدم إفشاء (NDA)",
];

$label = $typeLabelMap[$contractType] ?? "عقد";

$systemPrompt =
  "أنت محامٍ سعودي محترف متخصص في صياغة العقود وفق أنظمة المملكة العربية السعودية. "
  . "اكتب {$label} كاملاً ومنظماً بعناوين وبنود مرقمة باللغة العربية الرسمية الفصحى. "
  . "يجب أن يتضمن العقد: الديباجة، تعريف الأطراف، موضوع العقد، الالتزامات، "
  . "المدة والأجر، بنود الإنهاء، تسوية النزاعات (المحاكم السعودية)، والتوقيعات. "
  . "ممنوع استخدام رموز ماركداون مثل ** أو ## أو `. "
  . "لا تخترع أسماء أو أرقام غير مذكورة — ضع ____ مكان أي معلومة ناقصة. "
  . "اكتب بصياغة قانونية واضحة ومهنية دون طرح أي أسئلة.";

$userPrompt =
  "اكتب عقداً كاملاً بناءً على البيانات التالية:\n"
  . "- نوع العقد: {$label}\n"
  . "- البيانات المُدخلة:\n"
  . json_encode($answers, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

$data = [
  "model"    => "gpt-4o",
  "messages" => [
    ["role" => "system", "content" => $systemPrompt],
    ["role" => "user",   "content" => $userPrompt],
  ],
  "max_tokens" => 2500,
];

$response = call_openai($data);
$text     = cleanup_text(openai_extract_output_text($response));

if ($text === "") {
  respond(["type" => "error", "message" => "تعذّر إنشاء العقد، حاول مرة أخرى."], 500);
}

$pdfInfo = generate_pdf_file($text, $label);

respond([
  "type"          => "contract",
  "text"          => $text,
  "pdf_url"       => $pdfInfo["file_url"],
  "contract_type" => $contractType,
]);