//
//  AudioAlarmJSONModels.swift
//  TestDemo
//
//  JSON structure returned by device `getAudioAlarmInfo` (including `audio_file_list` / `schedule_time_list`).
//

import Foundation

// MARK: - Root Structure

/// Corresponds to the top-level `audio_alarm_param` wrapper in device JSON.
struct AudioAlarmInfoResponse: Codable {
    let audioAlarmParam: AudioAlarmParam

    enum CodingKeys: String, CodingKey {
        case audioAlarmParam = "audio_alarm_param"
    }
}

// MARK: - audio_alarm_param

struct AudioAlarmParam: Codable {
    let audioFileList: [AudioAlarmFileItem]
    let scheduleTimeList: [AudioAlarmScheduleSlot]?

    enum CodingKeys: String, CodingKey {
        case audioFileList = "audio_file_list"
        case scheduleTimeList = "schedule_time_list"
    }
}

// MARK: - List Items

struct AudioAlarmFileItem: Codable {
    let audioFileId: Int
    let audioFileName: String
    let audioDisplayNum: Int

    enum CodingKeys: String, CodingKey {
        case audioFileId = "audio_file_id"
        case audioFileName = "audio_file_name"
        case audioDisplayNum = "audio_display_num"
    }
}

struct AudioAlarmScheduleSlot: Codable {
    let weekday: Int
    let sTime: Int
    let eTime: Int

    enum CodingKeys: String, CodingKey {
        case weekday
        case sTime = "s_time"
        case eTime = "e_time"
    }
}

// MARK: - Parsing

enum AudioAlarmInfoJSONParser {
    static func parse(_ jsonString: String) throws -> AudioAlarmInfoResponse {
        let data = Data(jsonString.utf8)
        let decoder = JSONDecoder()
        return try decoder.decode(AudioAlarmInfoResponse.self, from: data)
    }
}
