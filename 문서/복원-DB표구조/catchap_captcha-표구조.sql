-- catchap_captcha 표 구조 (2026-08-12 실측)
-- ★데이터는 한 줄도 들어 있지 않습니다. 구조만입니다.
-- 뽑은 법: 파드 안에서 SHOW CREATE TABLE (자격증명이 밖으로 안 나가게)

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- behavior_shadow_predictions  (실측 3534행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `behavior_shadow_predictions`;
CREATE TABLE `behavior_shadow_predictions` (
  `captcha_attempt_id` bigint unsigned NOT NULL,
  `behavior_attempt_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `detail` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `local_policy_mode` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `model_policy_mode` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `risk_score` double DEFAULT NULL,
  `risk_level` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `recommended_action` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `human_score` double DEFAULT NULL,
  `bot_risk_score` double DEFAULT NULL,
  `model_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `model_version` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `feature_schema_version` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reasons` json DEFAULT NULL,
  `main_captcha_verdict` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `final_verdict` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`captcha_attempt_id`),
  UNIQUE KEY `behavior_attempt_id` (`behavior_attempt_id`),
  CONSTRAINT `fk_shadow_prediction_attempt` FOREIGN KEY (`captcha_attempt_id`) REFERENCES `captcha_attempts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- behavior_summaries  (실측 3934행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `behavior_summaries`;
CREATE TABLE `behavior_summaries` (
  `attempt_id` bigint unsigned NOT NULL,
  `reaction_time_ms` int unsigned DEFAULT NULL,
  `total_duration_ms` int unsigned NOT NULL,
  `drag_count` int unsigned NOT NULL,
  `wrong_object_count` int unsigned NOT NULL,
  `average_speed` double NOT NULL,
  `speed_variance` double NOT NULL,
  `path_length` double NOT NULL,
  `path_curvature` double NOT NULL,
  `pause_count` int unsigned NOT NULL,
  PRIMARY KEY (`attempt_id`),
  CONSTRAINT `fk_summary_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `captcha_attempts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- captcha_attempts  (실측 3934행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `captcha_attempts`;
CREATE TABLE `captcha_attempts` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `challenge_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `selected_object_ids` json NOT NULL,
  `is_correct` tinyint(1) NOT NULL,
  `failure_reason` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `duration_ms` int unsigned NOT NULL,
  `behavior_summary` json DEFAULT NULL,
  `raw_event_path` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_attempt_challenge` (`challenge_id`),
  CONSTRAINT `fk_attempt_challenge` FOREIGN KEY (`challenge_id`) REFERENCES `captcha_challenges_v2` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3987 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- captcha_behavior_batches  (실측 75001행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `captcha_behavior_batches`;
CREATE TABLE `captcha_behavior_batches` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `challenge_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch_seq` int unsigned NOT NULL,
  `event_count` smallint unsigned NOT NULL,
  `previous_receipt_hash` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payload_hash` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `receipt_hash` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `events_json` json NOT NULL,
  `received_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_behavior_batch` (`challenge_id`,`batch_seq`),
  KEY `idx_behavior_batch_challenge` (`challenge_id`,`batch_seq`),
  CONSTRAINT `fk_behavior_batch_challenge` FOREIGN KEY (`challenge_id`) REFERENCES `captcha_challenges_v2` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=75002 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- captcha_behavior_fingerprints  (실측 3036행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `captcha_behavior_fingerprints`;
CREATE TABLE `captcha_behavior_fingerprints` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `session_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `signature` char(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `risk_score` int NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_fp_sig` (`signature`,`created_at`),
  KEY `idx_fp_created` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3037 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- captcha_behavior_sessions  (실측 5733행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `captcha_behavior_sessions`;
CREATE TABLE `captcha_behavior_sessions` (
  `challenge_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `nonce_hash` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `next_batch_seq` int unsigned NOT NULL DEFAULT '0',
  `last_receipt_hash` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `received_event_count` int unsigned NOT NULL DEFAULT '0',
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`challenge_id`),
  CONSTRAINT `fk_behavior_session_challenge` FOREIGN KEY (`challenge_id`) REFERENCES `captcha_challenges_v2` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- captcha_challenge_objects  (실측 21790행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `captcha_challenge_objects`;
CREATE TABLE `captcha_challenge_objects` (
  `challenge_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `object_id` bigint unsigned NOT NULL,
  `temporary_object_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`challenge_id`,`temporary_object_id`),
  UNIQUE KEY `uq_challenge_object` (`challenge_id`,`object_id`),
  KEY `fk_map_object` (`object_id`),
  CONSTRAINT `fk_map_challenge` FOREIGN KEY (`challenge_id`) REFERENCES `captcha_challenges_v2` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_map_object` FOREIGN KEY (`object_id`) REFERENCES `captcha_objects` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- captcha_challenges_v2  (실측 6240행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `captcha_challenges_v2`;
CREATE TABLE `captcha_challenges_v2` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `question_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `session_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `purpose` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime(6) NOT NULL,
  `attempt_count` tinyint unsigned NOT NULL DEFAULT '0',
  `status` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'issued',
  `created_at` datetime(6) NOT NULL,
  `verified_at` datetime(6) DEFAULT NULL,
  `client_ip_hash` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `lecture_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pow_bits` tinyint unsigned NOT NULL DEFAULT '0',
  `honeypot_ids` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `idx_challenge_expiry` (`expires_at`),
  KEY `idx_challenge_rate` (`client_ip_hash`,`created_at`),
  KEY `fk_challenge_question` (`question_id`),
  CONSTRAINT `fk_challenge_question` FOREIGN KEY (`question_id`) REFERENCES `captcha_questions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- captcha_objects  (실측 34508행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `captcha_objects`;
CREATE TABLE `captcha_objects` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `question_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `object_key` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `label` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `bbox_x` double NOT NULL,
  `bbox_y` double NOT NULL,
  `bbox_width` double NOT NULL,
  `bbox_height` double NOT NULL,
  `role` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `piece_path` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_question_object` (`question_id`,`object_key`),
  KEY `idx_object_question` (`question_id`),
  CONSTRAINT `fk_object_question` FOREIGN KEY (`question_id`) REFERENCES `captcha_questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=36029 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- captcha_questions  (실측 6903행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `captcha_questions`;
CREATE TABLE `captcha_questions` (
  `id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `instruction_ko` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `instruction_en` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `source_question_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `image_path` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `image_width` int unsigned NOT NULL,
  `image_height` int unsigned NOT NULL,
  `difficulty` tinyint unsigned NOT NULL DEFAULT '2',
  `status` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'draft',
  `review_status` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `reviewer` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reviewed_at` datetime(6) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `served_count` int NOT NULL DEFAULT '0',
  `last_served_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_question_status` (`status`,`review_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- captcha_review_claims  (실측 1행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `captcha_review_claims`;
CREATE TABLE `captcha_review_claims` (
  `queue_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `reviewer_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `claimed_at` datetime(6) NOT NULL,
  `expires_at` datetime(6) NOT NULL,
  PRIMARY KEY (`queue_id`),
  KEY `idx_review_claim_reviewer` (`reviewer_id`),
  KEY `idx_review_claim_expiry` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- captcha_review_decisions  (실측 3086행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `captcha_review_decisions`;
CREATE TABLE `captcha_review_decisions` (
  `queue_id` varchar(160) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `review_status` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `reviewer` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `question_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reviewed_at` datetime(6) NOT NULL,
  PRIMARY KEY (`queue_id`),
  KEY `idx_review_decision_status` (`review_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- captcha_tokens  (실측 2824행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `captcha_tokens`;
CREATE TABLE `captcha_tokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `challenge_id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `token_hash` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `purpose` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `session_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime(6) NOT NULL,
  `consumed_at` datetime(6) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `lecture_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token_hash` (`token_hash`),
  KEY `fk_token_challenge` (`challenge_id`),
  CONSTRAINT `fk_token_challenge` FOREIGN KEY (`challenge_id`) REFERENCES `captcha_challenges_v2` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2826 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- captcha_users  (실측 0행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `captcha_users`;
CREATE TABLE `captcha_users` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(320) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- label_admin_sessions  (실측 3행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `label_admin_sessions`;
CREATE TABLE `label_admin_sessions` (
  `token_hash` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint unsigned NOT NULL,
  `expires_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `last_seen_at` datetime(6) NOT NULL,
  `ip_hash` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`token_hash`),
  KEY `idx_admin_session_user` (`user_id`),
  KEY `idx_admin_session_expiry` (`expires_at`),
  CONSTRAINT `fk_admin_session_user` FOREIGN KEY (`user_id`) REFERENCES `label_admin_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- label_admin_users  (실측 4행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `label_admin_users`;
CREATE TABLE `label_admin_users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'admin',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `must_change_password` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `last_login_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- label_events  (실측 727행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `label_events`;
CREATE TABLE `label_events` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `task_id` bigint unsigned DEFAULT NULL,
  `actor_id` bigint unsigned DEFAULT NULL,
  `event_type` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `details` json DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_label_event_task` (`task_id`,`id`),
  KEY `idx_label_event_actor` (`actor_id`,`id`),
  CONSTRAINT `fk_label_event_actor` FOREIGN KEY (`actor_id`) REFERENCES `label_admin_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_label_event_task` FOREIGN KEY (`task_id`) REFERENCES `label_tasks` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=767 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- label_legacy_reviews  (실측 1531행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `label_legacy_reviews`;
CREATE TABLE `label_legacy_reviews` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `source_server` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `source_file` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `source_line` int unsigned NOT NULL,
  `source_sha256` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `question_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `review_status` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `reviewer` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `attributed_to` bigint unsigned DEFAULT NULL,
  `mapped_task_id` bigint unsigned DEFAULT NULL,
  `payload` json NOT NULL,
  `reviewed_at` datetime(6) DEFAULT NULL,
  `imported_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_legacy_review_source` (`source_server`,`source_file`,`source_line`),
  KEY `idx_legacy_review_queue` (`queue_id`,`reviewed_at`),
  KEY `idx_legacy_review_status` (`review_status`,`reviewed_at`),
  KEY `fk_legacy_review_actor` (`attributed_to`),
  KEY `fk_legacy_review_task` (`mapped_task_id`),
  CONSTRAINT `fk_legacy_review_actor` FOREIGN KEY (`attributed_to`) REFERENCES `label_admin_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_legacy_review_task` FOREIGN KEY (`mapped_task_id`) REFERENCES `label_tasks` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=1532 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- label_publish_jobs  (실측 376행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `label_publish_jobs`;
CREATE TABLE `label_publish_jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `task_id` bigint unsigned NOT NULL,
  `revision_id` bigint unsigned NOT NULL,
  `requested_by` bigint unsigned DEFAULT NULL,
  `status` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `attempt_count` int unsigned NOT NULL DEFAULT '0',
  `error_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` datetime(6) NOT NULL,
  `started_at` datetime(6) DEFAULT NULL,
  `completed_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_publish_revision` (`revision_id`),
  KEY `idx_publish_status` (`status`,`created_at`),
  KEY `fk_publish_task` (`task_id`),
  KEY `fk_publish_actor` (`requested_by`),
  CONSTRAINT `fk_publish_actor` FOREIGN KEY (`requested_by`) REFERENCES `label_admin_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_publish_revision` FOREIGN KEY (`revision_id`) REFERENCES `label_revisions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_publish_task` FOREIGN KEY (`task_id`) REFERENCES `label_tasks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=380 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- label_revisions  (실측 2422행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `label_revisions`;
CREATE TABLE `label_revisions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `task_id` bigint unsigned NOT NULL,
  `version` int unsigned NOT NULL,
  `actor_id` bigint unsigned DEFAULT NULL,
  `action` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` json NOT NULL,
  `note` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imported` tinyint(1) NOT NULL DEFAULT '0',
  `source_file` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_line` int unsigned DEFAULT NULL,
  `source_sha256` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_label_revision_version` (`task_id`,`version`),
  KEY `idx_label_revision_task` (`task_id`,`id`),
  KEY `fk_label_revision_actor` (`actor_id`),
  CONSTRAINT `fk_label_revision_actor` FOREIGN KEY (`actor_id`) REFERENCES `label_admin_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_label_revision_task` FOREIGN KEY (`task_id`) REFERENCES `label_tasks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2578 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- label_tasks  (실측 1547행 — 여기에는 안 담김)
DROP TABLE IF EXISTS `label_tasks`;
CREATE TABLE `label_tasks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `queue_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `question_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `existing_question_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_payload` json NOT NULL,
  `current_payload` json NOT NULL,
  `status` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `assigned_to` bigint unsigned DEFAULT NULL,
  `claimed_at` datetime(6) DEFAULT NULL,
  `lease_expires_at` datetime(6) DEFAULT NULL,
  `claimed_from_status` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `version` int unsigned NOT NULL DEFAULT '0',
  `current_batch` tinyint(1) NOT NULL DEFAULT '0',
  `expected_target_count` int unsigned NOT NULL DEFAULT '1',
  `reconciliation_reason` json DEFAULT NULL,
  `source_file` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `source_line` int unsigned NOT NULL,
  `source_sha256` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `published_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `queue_id` (`queue_id`),
  UNIQUE KEY `uq_label_task_assignee_status` (`assigned_to`,`status`),
  KEY `idx_label_task_work` (`status`,`current_batch`,`updated_at`),
  KEY `idx_label_task_assignee` (`assigned_to`,`status`),
  CONSTRAINT `fk_label_task_assignee` FOREIGN KEY (`assigned_to`) REFERENCES `label_admin_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=1560 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;