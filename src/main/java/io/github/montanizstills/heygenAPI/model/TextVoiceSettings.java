package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.model.interfaces.VoiceSettings;
import lombok.Getter;
import lombok.Setter;

// ==================== Text Voice Settings ====================
@Setter
@Getter
@JsonInclude(JsonInclude.Include.NON_NULL)
class TextVoiceSettings implements VoiceSettings {
    // Getters and Setters
    @JsonProperty("type")
    private String type = "text";

    @JsonProperty("voice_id")
    private String voiceId;

    @JsonProperty("input_text")
    private String inputText;

    @JsonProperty("speed")
    private Float speed = 1.0f;

    @JsonProperty("pitch")
    private Integer pitch = 0;

    @JsonProperty("emotion")
    private String emotion;

    @JsonProperty("locale")
    private String locale;

    @JsonProperty("elevenlabs_settings")
    private ElevenLabsSettings elevenLabsSettings;

    // Constructors
    public TextVoiceSettings() {
    }

    public TextVoiceSettings(String voiceId, String inputText) {
        this.voiceId = voiceId;
        this.inputText = inputText;
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
