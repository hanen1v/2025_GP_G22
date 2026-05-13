<?php
$DB_HOST = getenv('DB_HOST') ?: 'localhost';
$DB_PORT = getenv('DB_PORT') ?: '3306';
$DB_NAME = getenv('DB_NAME') ?: 'mujeer';
$DB_USER = getenv('DB_USER') ?: 'root';
$DB_PASS = getenv('DB_PASS') ?: '';

define('ONESIGNAL_APP_ID',       getenv('ONESIGNAL_APP_ID')       ?: '');
define('ONESIGNAL_REST_API_KEY', getenv('ONESIGNAL_REST_API_KEY') ?: '');
define('OPENAI_API_KEY',         getenv('OPENAI_API_KEY')         ?: '');

error_reporting(E_ALL);
ini_set('display_errors', 1);

// PDO connection (always available on Railway)
try {
    $dsn = "mysql:host=$DB_HOST;port=$DB_PORT;dbname=$DB_NAME;charset=utf8mb4";
    $pdo = new PDO($dsn, $DB_USER, $DB_PASS, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'DB connection failed: ' . $e->getMessage()]);
    exit;
}

// mysqli-compatible wrapper so existing code works unchanged
class MysqliWrapper {
    public PDO $pdo;
    public string $error = '';

    public function __construct(PDO $pdo) {
        $this->pdo = $pdo;
    }

    public function query(string $sql) {
        try {
            $stmt = $this->pdo->query($sql);
            return new MysqliResult($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            $this->error = $e->getMessage();
            return false;
        }
    }

    public function prepare(string $sql) {
        try {
            $stmt = $this->pdo->prepare($sql);
            return new MysqliStmt($stmt, $this->pdo);
        } catch (PDOException $e) {
            $this->error = $e->getMessage();
            return false;
        }
    }

    public function real_escape_string(string $s): string {
        return addslashes($s);
    }

    public function set_charset(string $charset): bool {
        return true;
    }

    public function get_insert_id(): string {
        return $this->pdo->lastInsertId();
    }
}

class MysqliStmt {
    private $stmt;
    private PDO $pdo;
    public string $error = '';
    private array $boundValues = [];

    public function __construct($stmt, PDO $pdo) {
        $this->stmt = $stmt;
        $this->pdo  = $pdo;
    }

    public function bind_param(string $types, &...$vars): bool {
        foreach ($vars as $i => $v) {
            $this->boundValues[$i + 1] = $v;
            $this->stmt->bindValue($i + 1, $v);
        }
        return true;
    }

    public function execute(): bool {
        try {
            return $this->stmt->execute();
        } catch (PDOException $e) {
            $this->error = $e->getMessage();
            return false;
        }
    }

    public function get_result(): MysqliResult {
        return new MysqliResult($this->stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function affected_rows(): int {
        return $this->stmt->rowCount();
    }

    public function insert_id(): string {
        return $this->pdo->lastInsertId();
    }
}

class MysqliResult {
    private array $rows;
    private int $pos = 0;
    public int $num_rows;

    public function __construct(array $rows) {
        $this->rows     = $rows;
        $this->num_rows = count($rows);
    }

    public function fetch_assoc(): ?array {
        return $this->rows[$this->pos++] ?? null;
    }

    public function fetch_all(int $mode = MYSQLI_ASSOC): array {
        return $this->rows;
    }
}

$conn = new MysqliWrapper($pdo);


// Push notification helper
function send_push(array $playerIds, string $title, string $body, array $data = []) {
    if (empty($playerIds)) return ['ok' => false, 'reason' => 'No players'];

    $payload = [
        'app_id'             => ONESIGNAL_APP_ID,
        'include_player_ids' => array_values($playerIds),
        'headings'           => ['ar' => $title, 'en' => $title],
        'contents'           => ['ar' => $body,  'en' => $body],
        'data'               => $data ?: ['type' => 'notification'],
    ];

    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL            => 'https://onesignal.com/api/v1/notifications',
        CURLOPT_HTTPHEADER     => [
            'Authorization: Bearer ' . ONESIGNAL_REST_API_KEY,
            'Content-Type: application/json; charset=utf-8',
        ],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => json_encode($payload, JSON_UNESCAPED_UNICODE),
        CURLOPT_TIMEOUT        => 15,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => false,
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);
    curl_close($ch);

    if ($response === false) return ['ok' => false, 'error' => $error];
    $result = json_decode($response, true);
    if ($httpCode !== 200) return ['ok' => false, 'error' => "HTTP $httpCode", 'response' => $result];
    return ['ok' => true, 'response' => $result];
}