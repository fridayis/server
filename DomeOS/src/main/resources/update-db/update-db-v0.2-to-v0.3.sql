UPDATE global SET `value`=`pub.domeos.org/domeos/build:0.3` WHERE `type`=`BUILD_IMAGE`;

INSERT INTO global(type, value) VALUES ('PUBLIC_REGISTRY_URL', 'http://pub.domeos.org');
DROP TABLE k8s_events;
CREATE TABLE IF NOT EXISTS `k8s_events` (
  `id` INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `version` VARCHAR(255) NOT NULL,
  `clusterId` INT(11) NOT NULL,
  `deployId` INT(11) NOT NULL DEFAULT -1,
  `namespace` VARCHAR(255) NOT NULL,
  `eventKind` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `host` VARCHAR(255),
  `content` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE INDEX `k8s_events_kind_index` ON k8s_events(`clusterId`, `namespace`, `eventKind`);
CREATE INDEX `k8s_events_name_index` ON k8s_events(`clusterId`, `namespace`, `name`);
CREATE INDEX `k8s_events_host_index` ON k8s_events(`host`);
CREATE INDEX `k8s_events_deploy_index` ON k8s_events(`clusterId`, `namespace`, `deployId`);

-- alarm event info
CREATE TABLE IF NOT EXISTS `alarm_event_info_draft` (
  `id` VARCHAR(64) NOT NULL PRIMARY KEY,
  `endpoint` VARCHAR(128) NULL DEFAULT NULL,
  `metric` VARCHAR(128) NULL DEFAULT NULL,
  `counter` VARCHAR(128) NULL DEFAULT NULL,
  `func` VARCHAR(128) NULL DEFAULT NULL,
  `left_value` VARCHAR(128) NULL DEFAULT NULL,
  `operator` VARCHAR(128) NULL DEFAULT NULL,
  `right_value` VARCHAR(128) NULL DEFAULT NULL,
  `note` VARCHAR(4096) NULL DEFAULT NULL,
  `max_step` INT(20) NULL DEFAULT NULL,
  `current_step` INT(20) NULL DEFAULT NULL,
  `priority` INT(20) NULL DEFAULT NULL,
  `status` VARCHAR(128) NULL DEFAULT NULL,
  `timestamp` INT(20) NULL DEFAULT NULL,
  `expression_id` INT(20) NULL DEFAULT NULL,
  `strategy_id` INT(20) NULL DEFAULT NULL,
  `template_id` INT(20) NULL DEFAULT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- alarm callback
CREATE TABLE IF NOT EXISTS `alarm_callback_info` (
  `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `url` VARCHAR(256) NULL DEFAULT NULL,
  `beforeCallbackSms` TINYINT(1) NULL DEFAULT NULL,
  `beforeCallbackMail` TINYINT(1) NULL DEFAULT NULL,
  `afterCallbackSms` TINYINT(1) NULL DEFAULT NULL,
  `afterCallbackMail` TINYINT(1) NULL DEFAULT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- alarm host info
CREATE TABLE IF NOT EXISTS `alarm_host_info` (
  `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `hostname` VARCHAR(128) NULL DEFAULT NULL,
  `ip` VARCHAR(128) NULL DEFAULT NULL,
  `cluster` VARCHAR(128) NULL DEFAULT NULL,
  `createTime` BIGINT(20) NULL DEFAULT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- alarm host group info
CREATE TABLE IF NOT EXISTS `alarm_host_group_info` (
  `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `hostGroupName` VARCHAR(128) NULL DEFAULT NULL,
  `creatorId` INT(11) NULL DEFAULT NULL,
  `creatorName` VARCHAR(128) NULL DEFAULT NULL,
  `createTime` BIGINT(20) NULL DEFAULT NULL,
  `updateTime` BIGINT(20) NULL DEFAULT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- alarm strategy info
CREATE TABLE IF NOT EXISTS `alarm_strategy_info` (
  `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `metric` VARCHAR(64) NULL DEFAULT NULL,
  `tag` VARCHAR(128) NULL DEFAULT NULL,
  `pointNum` INT(11) NULL DEFAULT NULL,
  `aggregateType` VARCHAR(64) NULL DEFAULT NULL,
  `operator` VARCHAR(64) NULL DEFAULT NULL,
  `rightValue` DOUBLE NULL DEFAULT NULL,
  `note` VARCHAR(1024) NULL DEFAULT NULL,
  `maxStep` INT(11) NULL DEFAULT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- alarm template info
CREATE TABLE IF NOT EXISTS `alarm_template_info` (
  `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `templateName` VARCHAR(64) NULL DEFAULT NULL,
  `templateType` VARCHAR(64) NULL DEFAULT NULL,
  `creatorId` INT(11) NULL DEFAULT NULL,
  `creatorName` VARCHAR(128) NULL DEFAULT NULL,
  `createTime` BIGINT(20) NULL DEFAULT NULL,
  `updateTime` BIGINT(20) NULL DEFAULT NULL,
  `callbackId` INT(11) NULL DEFAULT NULL,
  `deployId` INT(11) NULL DEFAULT NULL,
  `isRemoved` TINYINT(4) NOT NULL DEFAULT '0'
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- alarm host group & host bind
CREATE TABLE IF NOT EXISTS `alarm_host_group_host_bind` (
  `hostGroupId` INT(11) NOT NULL,
  `hostId` INT(11) NOT NULL,
  `bindTime` BIGINT(20) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- alarm template & host group bind
CREATE TABLE IF NOT EXISTS `alarm_template_host_group_bind` (
  `templateId` INT(11) NOT NULL,
  `hostGroupId` INT(11) NOT NULL,
  `bindTime` BIGINT(20) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- alarm template & user group bind
CREATE TABLE IF NOT EXISTS `alarm_template_user_group_bind` (
  `templateId` INT(11) NOT NULL,
  `userGroupId` INT(11) NOT NULL,
  `bindTime` BIGINT(20) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- alarm template & strategy bind
CREATE TABLE IF NOT EXISTS `alarm_template_strategy_bind` (
  `templateId` INT(11) NOT NULL,
  `strategyId` INT(11) NOT NULL,
  `bindTime` BIGINT(20) NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- alarm link info
CREATE TABLE IF NOT EXISTS `alarm_link_info` (
  `id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `content` MEDIUMTEXT NULL DEFAULT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

create database if not exists `portal`;

DROP TABLE if exists `portal`.`action`;
CREATE TABLE `portal`.`action` (
	`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`uic` VARCHAR(255) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`url` VARCHAR(255) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`callback` TINYINT(4) NOT NULL DEFAULT '0',
	`before_callback_sms` TINYINT(4) NOT NULL DEFAULT '0',
	`before_callback_mail` TINYINT(4) NOT NULL DEFAULT '0',
	`after_callback_sms` TINYINT(4) NOT NULL DEFAULT '0',
	`after_callback_mail` TINYINT(4) NOT NULL DEFAULT '0',
	PRIMARY KEY (`id`)
)
COLLATE='utf8_unicode_ci'
ENGINE=InnoDB
AUTO_INCREMENT=3
;

DROP TABLE if exists `portal`.`expression`;
CREATE TABLE `portal`.`expression` (
	`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`expression` VARCHAR(1024) NOT NULL COLLATE 'utf8_unicode_ci',
	`func` VARCHAR(16) NOT NULL DEFAULT 'all(#1)' COLLATE 'utf8_unicode_ci',
	`op` VARCHAR(8) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`right_value` VARCHAR(16) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`max_step` INT(11) NOT NULL DEFAULT '1',
	`priority` TINYINT(4) NOT NULL DEFAULT '0',
	`note` VARCHAR(1024) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`action_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
	`create_user` VARCHAR(64) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`pause` TINYINT(1) NOT NULL DEFAULT '0',
	PRIMARY KEY (`id`)
)
COLLATE='utf8_unicode_ci'
ENGINE=InnoDB
;

DROP TABLE if exists `portal`.`grp`;
CREATE TABLE `portal`.`grp` (
	`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`grp_name` VARCHAR(255) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`create_user` VARCHAR(64) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`create_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`come_from` TINYINT(4) NOT NULL DEFAULT '0',
	PRIMARY KEY (`id`),
	UNIQUE INDEX `idx_host_grp_grp_name` (`grp_name`)
)
COLLATE='utf8_unicode_ci'
ENGINE=InnoDB
AUTO_INCREMENT=1000
;

DROP TABLE if exists `portal`.`grp_host`;
CREATE TABLE `portal`.`grp_host` (
	`grp_id` INT(10) UNSIGNED NOT NULL,
	`host_id` INT(10) UNSIGNED NOT NULL,
	INDEX `idx_grp_host_grp_id` (`grp_id`),
	INDEX `idx_grp_host_host_id` (`host_id`)
)
COLLATE='utf8_unicode_ci'
ENGINE=InnoDB
;

DROP TABLE if exists `portal`.`grp_tpl`;
CREATE TABLE `portal`.`grp_tpl` (
	`grp_id` INT(10) UNSIGNED NOT NULL,
	`tpl_id` INT(10) UNSIGNED NOT NULL,
	`bind_user` VARCHAR(64) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	INDEX `idx_grp_tpl_grp_id` (`grp_id`),
	INDEX `idx_grp_tpl_tpl_id` (`tpl_id`)
)
COLLATE='utf8_unicode_ci'
ENGINE=InnoDB
;

DROP TABLE if exists `portal`.`host`;
CREATE TABLE `portal`.`host` (
	`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`hostname` VARCHAR(255) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`ip` VARCHAR(16) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`agent_version` VARCHAR(16) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`plugin_version` VARCHAR(128) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`maintain_begin` INT(10) UNSIGNED NOT NULL DEFAULT '0',
	`maintain_end` INT(10) UNSIGNED NOT NULL DEFAULT '0',
	`update_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE INDEX `idx_host_hostname` (`hostname`)
)
COLLATE='utf8_unicode_ci'
ENGINE=InnoDB
AUTO_INCREMENT=48095996
;

DROP TABLE if exists `portal`.`mockcfg`;
CREATE TABLE `portal`.`mockcfg` (
	`id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
	`name` VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'name of mockcfg, used for uuid' COLLATE 'utf8_unicode_ci',
	`obj` VARCHAR(10240) NOT NULL DEFAULT '' COMMENT 'desc of object' COLLATE 'utf8_unicode_ci',
	`obj_type` VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'type of object, host or group or other' COLLATE 'utf8_unicode_ci',
	`metric` VARCHAR(128) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`tags` VARCHAR(1024) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`dstype` VARCHAR(32) NOT NULL DEFAULT 'GAUGE' COLLATE 'utf8_unicode_ci',
	`step` INT(11) UNSIGNED NOT NULL DEFAULT '60',
	`mock` DOUBLE NOT NULL DEFAULT '0' COMMENT 'mocked value when nodata occurs',
	`creator` VARCHAR(64) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`t_create` DATETIME NOT NULL COMMENT 'create time',
	`t_modify` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'last modify time',
	PRIMARY KEY (`id`),
	UNIQUE INDEX `uniq_name` (`name`)
)
COLLATE='utf8_unicode_ci'
ENGINE=InnoDB
AUTO_INCREMENT=2
;

DROP TABLE if exists `portal`.`plugin_dir`;
CREATE TABLE `portal`.`plugin_dir` (
	`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`grp_id` INT(10) UNSIGNED NOT NULL,
	`dir` VARCHAR(255) NOT NULL COLLATE 'utf8_unicode_ci',
	`create_user` VARCHAR(64) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`create_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	INDEX `idx_plugin_dir_grp_id` (`grp_id`)
)
COLLATE='utf8_unicode_ci'
ENGINE=InnoDB
AUTO_INCREMENT=4
;

DROP TABLE if exists `portal`.`strategy`;
CREATE TABLE `portal`.`strategy` (
	`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`metric` VARCHAR(128) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`tags` VARCHAR(256) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`max_step` INT(11) NOT NULL DEFAULT '1',
	`priority` TINYINT(4) NOT NULL DEFAULT '0',
	`func` VARCHAR(16) NOT NULL DEFAULT 'all(#1)' COLLATE 'utf8_unicode_ci',
	`op` VARCHAR(8) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`right_value` VARCHAR(64) NOT NULL COLLATE 'utf8_unicode_ci',
	`note` VARCHAR(128) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`run_begin` VARCHAR(16) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`run_end` VARCHAR(16) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`tpl_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
	PRIMARY KEY (`id`),
	INDEX `idx_strategy_tpl_id` (`tpl_id`)
)
COLLATE='utf8_unicode_ci'
ENGINE=InnoDB
AUTO_INCREMENT=8
;

DROP TABLE if exists `portal`.`tpl`;
CREATE TABLE `portal`.`tpl` (
	`id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`tpl_name` VARCHAR(255) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`parent_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
	`action_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
	`create_user` VARCHAR(64) NOT NULL DEFAULT '' COLLATE 'utf8_unicode_ci',
	`create_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE INDEX `idx_tpl_name` (`tpl_name`),
	INDEX `idx_tpl_create_user` (`create_user`)
)
COLLATE='utf8_unicode_ci'
ENGINE=InnoDB
AUTO_INCREMENT=5
;