-- Database installation script for dy_name_tag
-- Run this SQL in your database before starting the resource

-- 玩家超级标签表
CREATE TABLE IF NOT EXISTS `dy_supertags` (
    `identifier` VARCHAR(100) NOT NULL COMMENT '玩家唯一标识',
    `playername` VARCHAR(100) DEFAULT '' COMMENT '角色名',
    `current_title` VARCHAR(255) DEFAULT '' COMMENT '当前使用的标签',
    `color` VARCHAR(20) DEFAULT '#FFFFFF' COMMENT '标签颜色',
    `all_titles` JSON DEFAULT NULL COMMENT '拥有的所有标签',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='玩家超级标签';
