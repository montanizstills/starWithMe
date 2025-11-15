package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.model.interfaces.VoiceSettings;
import lombok.Getter;
import lombok.Setter;

// ==================== Audio Voice Settings ====================
@Setter
@Getter
@JsonInclude(JsonInclude.Include.NON_NULL)
class AudioVoiceSettings implements VoiceSettings {
    @JsonProperty("type")
    private String type = "audio";

    @JsonProperty("audio_url")
    private String audioUrl;

    @JsonProperty("audio_asset_id")
    private String audioAssetId;

    public AudioVoiceSettings() {
    }

    public AudioVoiceSettings(String audioUrl, String audioAssetId) {
        this.audioUrl = audioUrl;
        this.audioAssetId = audioAssetId;
    }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}
