package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.model.interfaces.VoiceSettings;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TextVoiceSettings implements VoiceSettings {
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

}
