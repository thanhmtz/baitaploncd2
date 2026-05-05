-- ============================================================
-- HEALTH TRACKER APP - MYSQL DATABASE SCHEMA
-- ============================================================

-- ============================================================
-- 1. USER & AUTHENTICATION
-- ============================================================

CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    avatar TEXT,
    height FLOAT,
    weight FLOAT,
    age INT,
    gender VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE user_profiles (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL UNIQUE,
    bio TEXT,
    goals TEXT,
    daily_calorie_goal INT DEFAULT 2000,
    daily_water_goal FLOAT DEFAULT 2000,
    sleep_goal FLOAT DEFAULT 8,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- 2. DIARY MODULE - NUTRITION
-- ============================================================

CREATE TABLE meals (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    type ENUM('Breakfast', 'Lunch', 'Dinner', 'Snack') NOT NULL,
    date DATE NOT NULL,
    total_calories INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_meals_user_date (user_id, date)
);

CREATE TABLE foods (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    calories INT NOT NULL,
    protein FLOAT,
    carbs FLOAT,
    fat FLOAT,
    serving_size FLOAT DEFAULT 100,
    barcode VARCHAR(100) UNIQUE,
    INDEX idx_foods_name (name),
    INDEX idx_foods_barcode (barcode)
);

CREATE TABLE meal_foods (
    id VARCHAR(36) PRIMARY KEY,
    meal_id VARCHAR(36) NOT NULL,
    food_id VARCHAR(36) NOT NULL,
    quantity FLOAT NOT NULL DEFAULT 1,
    FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
    FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
);

-- ============================================================
-- 3. DIARY MODULE - WATER
-- ============================================================

CREATE TABLE water_intakes (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    amount FLOAT NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_water_user_date (user_id, date)
);

-- ============================================================
-- 4. DIARY MODULE - WEIGHT
-- ============================================================

CREATE TABLE weights (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    weight FLOAT NOT NULL,
    date DATE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_weights_user_date (user_id, date)
);

-- ============================================================
-- 5. DIARY MODULE - SLEEP
-- ============================================================

CREATE TABLE sleeps (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    sleep_time TIME NOT NULL,
    wake_time TIME NOT NULL,
    date DATE NOT NULL,
    total_hours FLOAT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_sleeps_user_date (user_id, date)
);

-- ============================================================
-- 6. DIARY MODULE - HEART RATE
-- ============================================================

CREATE TABLE heart_rates (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    bpm INT NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_heart_rates_user_date (user_id, date)
);

-- ============================================================
-- 7. RECIPES MODULE
-- ============================================================

CREATE TABLE recipes (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    image TEXT,
    calories INT,
    protein FLOAT,
    carbs FLOAT,
    fat FLOAT,
    servings INT DEFAULT 1,
    prep_time INT,
    cook_time INT,
    created_by VARCHAR(36),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE recipe_ingredients (
    id VARCHAR(36) PRIMARY KEY,
    recipe_id VARCHAR(36) NOT NULL,
    food_id VARCHAR(36) NOT NULL,
    quantity FLOAT,
    unit VARCHAR(50),
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
);

CREATE TABLE recipe_steps (
    id VARCHAR(36) PRIMARY KEY,
    recipe_id VARCHAR(36) NOT NULL,
    step_number INT NOT NULL,
    description TEXT NOT NULL,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
);

CREATE TABLE favorite_recipes (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    recipe_id VARCHAR(36) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_recipe (user_id, recipe_id)
);

-- ============================================================
-- 8. WORKOUTS MODULE
-- ============================================================

CREATE TABLE workout_plans (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    goal VARCHAR(100),
    duration INT,
    difficulty VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE workouts (
    id VARCHAR(36) PRIMARY KEY,
    plan_id VARCHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    day_number INT,
    exercises JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE
);

CREATE TABLE exercises (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    video_url TEXT,
    image TEXT,
    duration INT,
    reps INT,
    sets INT
);

CREATE TABLE user_workouts (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    workout_id VARCHAR(36) NOT NULL,
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    status ENUM('InProgress', 'Completed') DEFAULT 'InProgress',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE
);

-- ============================================================
-- 9. COMMUNITY MODULE
-- ============================================================

CREATE TABLE posts (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    content TEXT,
    image TEXT,
    recipe_id VARCHAR(36),
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE SET NULL,
    INDEX idx_posts_user (user_id),
    INDEX idx_posts_created (created_at)
);

CREATE TABLE likes (
    id VARCHAR(36) PRIMARY KEY,
    post_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_post_user_like (post_id, user_id),
    INDEX idx_likes_post (post_id)
);

CREATE TABLE comments (
    id VARCHAR(36) PRIMARY KEY,
    post_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_comments_post (post_id)
);

-- ============================================================
-- 10. MESSAGES MODULE
-- ============================================================

CREATE TABLE conversations (
    id VARCHAR(36) PRIMARY KEY,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE conversation_participants (
    id VARCHAR(36) PRIMARY KEY,
    conversation_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_conv_user (conversation_id, user_id)
);

CREATE TABLE messages (
    id VARCHAR(36) PRIMARY KEY,
    conversation_id VARCHAR(36) NOT NULL,
    sender_id VARCHAR(36) NOT NULL,
    content TEXT,
    image TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_messages_conversation (conversation_id)
);

-- ============================================================
-- 11. CHALLENGES MODULE
-- ============================================================

CREATE TABLE challenges (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type ENUM('Daily', 'Weekly', 'Monthly') NOT NULL,
    goal VARCHAR(255),
    points INT DEFAULT 0,
    start_date DATE,
    end_date DATE
);

CREATE TABLE user_challenges (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    challenge_id VARCHAR(36) NOT NULL,
    progress INT DEFAULT 0,
    status ENUM('Active', 'Completed', 'Failed') DEFAULT 'Active',
    completed_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_challenge (user_id, challenge_id)
);

-- ============================================================
-- 12. MEDITATION MODULE
-- ============================================================

CREATE TABLE meditation_sessions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    duration INT NOT NULL,
    completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- 13. NOTIFICATIONS MODULE
-- ============================================================

CREATE TABLE notifications (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    type VARCHAR(50),
    is_read BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_notifications_user (user_id, is_read)
);

-- ============================================================
-- VIEWS (Optional)
-- ============================================================

-- View: Daily Summary
CREATE VIEW v_daily_summary AS
SELECT 
    u.id as user_id,
    u.name,
    DATE(COALESCE(m.date, w.date, wt.date, sl.date)) as summary_date,
    COALESCE(SUM(m.total_calories), 0) as total_calories,
    COALESCE(SUM(w.amount), 0) as total_water,
    COALESCE(MAX(wt.weight), 0) as weight,
    COALESCE(AVG(sl.total_hours), 0) as avg_sleep
FROM users u
LEFT JOIN meals m ON m.user_id = u.id
LEFT JOIN water_intakes w ON w.user_id = u.id
LEFT JOIN weights wt ON wt.user_id = u.id
LEFT JOIN sleeps sl ON sl.user_id = u.id
GROUP BY u.id, DATE(COALESCE(m.date, w.date, wt.date, sl.date));

-- View: User Profile with Stats
CREATE VIEW v_user_stats AS
SELECT 
    u.id as user_id,
    u.name,
    u.email,
    u.height,
    u.weight,
    u.age,
    up.daily_calorie_goal,
    up.daily_water_goal,
    up.sleep_goal,
    (SELECT COUNT(*) FROM posts WHERE user_id = u.id) as total_posts,
    (SELECT COUNT(*) FROM user_workouts WHERE user_id = u.id AND status = 'Completed') as total_workouts,
    (SELECT COUNT(*) FROM user_challenges WHERE user_id = u.id AND status = 'Completed') as total_challenges
FROM users u
LEFT JOIN user_profiles up ON up.user_id = u.id;