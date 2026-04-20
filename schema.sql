CREATE TABLE Users (
    id VARCHAR(255) PRIMARY KEY,  -- Firebase UID
    email VARCHAR(255) UNIQUE,    -- From FirebaseAuth (optional, for reference)
    scoreX INT DEFAULT 0,         -- Player wins
    scoreO INT DEFAULT 0,         -- AI wins (O)
    scoreD INT DEFAULT 0,         -- Draws
    lastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Games table (logical extension for full history)
CREATE TABLE Games (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255),
    winner ENUM('X', 'O', 'D') NULL,  -- X=player win, O=AI win, D=draw, NULL=ongoing
    move_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE
);

-- Moves table (from LogEntry class: n, playerPos, aiPos, aiReason)
CREATE TABLE Moves (
    id INT AUTO_INCREMENT PRIMARY KEY,
    game_id INT NOT NULL,
    move_number INT NOT NULL,
    player_pos VARCHAR(10) NOT NULL,  -- e.g. 'R1C1'
    ai_pos VARCHAR(10),               -- e.g. 'R1C2', NULL if game ended after player move
    ai_reason VARCHAR(100),           -- e.g. 'WIN DETECTED — executing winning move'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (game_id) REFERENCES Games(id) ON DELETE CASCADE,
    UNIQUE KEY unique_move_per_game (game_id, move_number)
);

-- Indexes for performance
CREATE INDEX idx_user_scores ON Users(scoreX, scoreO, scoreD);
CREATE INDEX idx_games_user ON Games(user_id);
CREATE INDEX idx_games_winner ON Games(winner);
CREATE INDEX idx_moves_game ON Moves(game_id);

-- Sample data insert (matching app logic)
INSERT INTO Users (id, email, scoreX, scoreO, scoreD) VALUES
('sample-uid-1', 'player@example.com', 5, 3, 2),
('sample-uid-2', 'ai-challenger@example.com', 2, 7, 1);