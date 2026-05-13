<?php
$DB_HOST = getenv('DB_HOST') ?: 'localhost';
$DB_PORT = getenv('DB_PORT') ?: '3306';
$DB_NAME = getenv('DB_NAME') ?: 'railway';
$DB_USER = getenv('DB_USER') ?: 'root';
$DB_PASS = getenv('DB_PASS') ?: '';

// Check if MYSQL_URL is available (Railway provides this)
$mysql_url = getenv('MYSQL_URL') ?: getenv('DATABASE_URL') ?: '';

define('ONESIGNAL_APP_ID',       getenv('ONESIGNAL_APP_ID')       ?: '');
define('ONESIGNAL_REST_API_KEY', getenv('ONESIGNAL_REST_API_KEY') ?: '');
define('OPENAI_API_KEY',         getenv('OPENAI_API_KEY')         ?: '');

error_reporting(E_ALL);
ini_set('display_errors', 1);

// Try connection using available drivers
$pdo = null;
$lastError = '';

// Method 1: Try PDO with mysql driver
if (!$pdo) {
    foreach (['mysql', 'mysqli'] as $driver) {
        if (in_array($driver === 'mysqli' ? 'mysql' : $driver, PDO::getAvailableDrivers())) {
            try {
                $dsn = "mysql:host=$DB_HOST;port=$DB_PORT;dbname=$DB_NAME;charset=utf8mb4";
                $pdo = new PDO($dsn, $DB_USER, $DB_PASS, [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]);
                break;
            } catch (PDOException $e) {
                $lastError = $e->getMessage();
            }
        }
    }
}

// Debug: show available drivers if connection failed
if (!$pdo) {
    http_response_code(500);
    $drivers = PDO::getAvailableDrivers();
    echo json_encode([
        'success' => false,
        'message' => 'DB connection failed: ' . $lastError,
        'available_drivers' => $drivers,
        'db_host' => $DB_HOST,
        'db_port' => $DB_PORT,
        'db_name' => $DB_NAME,
    ]);
    exit;
}

// mysqli-compatible wrapper
class MysqliWrapper {
    public PDO $pdo;
    public string $error = '';

    public function __construct(PDO $pdo) { $this->pdo = $pdo; }

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
            return new MysqliStmt($this->pdo->prepare($sql), $this->pdo);
        } catch (PDOException $e) {
            $this->error = $e->getMessage();
            return false;
        }
    }

    public function real_escape_string(string $s): string { return addslashes($s); }
    public function set_charset(string $charset): bool { return true; }
    public function get_insert_id(): string { return $this->pdo->lastInsertId(); }
}

class MysqliStmt {
    private $stmt;
    private PDO $pdo;
    public string $error = '';

    public function __construct($stmt, PDO $pdo) {
        $this->stmt = $stmt;
        $this->pdo  = $pdo;
    }

    public function bind_param(string $types, &...$vars): bool {
        foreach ($vars as $i => $v) $this->stmt->bindValue($i + 1, $v);
        return true;
    }

    public function execute(): bool {
        try { return $this->stmt->execute(); }
        catch (PDOException $e) { $this->error = $e->getMessage(); return false; }
    }

    public function get_result(): MysqliResult {
        return new MysqliResult($this->stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function affected_rows(): int { return $this->stmt->rowCount(); }
    public function insert_id(): string { return $this->pdo->lastInsertId(); }
}

class MysqliResult {
    private array $rows;
    private int $pos = 0;
    public int $num_rows;

    public function __construct(array $rows) {
        $this->rows     = $rows;
        $this->num_rows = count($rows);
    }

    public function fetch_assoc(): ?array { return $this->rows[$this->pos++] ?? null; }
    public function fetch_all(int $mode = 3): array { return $this->rows; }
}

$conn = new MysqliWrapper($pdo);

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
        CURLOPT_HTTPHEADER     => ['Authorization: Bearer ' . ONESIGNAL_REST_API_KEY, 'Content-Type: application/json; charset=utf-8'],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => json_encode($payload, JSON_UNESCAPED_UNICODE),
        CURLOPT_TIMEOUT        => 15,
        CURLOPT_SSL_VERIFYPEER => false,
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if (!$response) return ['ok' => false];
    $result = json_decode($response, true);
    return $httpCode === 200 ? ['ok' => true, 'response' => $result] : ['ok' => false, 'error' => "HTTP $httpCode"];
}