package io.github.montanizstills.heygenAPI.model.voice;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.interfaces.IVoiceSettings;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class VoiceSettings implements IVoiceSettings {
    @JsonProperty(value = "type", required = true)
    private String type = "text";

    @JsonProperty(value = "voice_id", required = true)
    private String voiceId;

    @JsonProperty(value = "input_text", required = true)
    private String inputText;

    @JsonProperty(value = "speed", defaultValue = "1")
    private Float speed = 1.0f;

    @JsonProperty(value = "pitch", defaultValue = "1")
    private Integer pitch = 0;

    @JsonProperty("emotion")
    private String emotion;

    @JsonProperty("locale")
    private String locale;

    @JsonProperty("elevenlabs_settings")
    private ElevenLabsSettings elevenLabsSettings;

    @JsonProperty(value = "audio_url", required = true)
    private String audioUrl;

    @JsonProperty(value = "audio_asset_id", required = true)
    private String audioAssetId;

    @JsonProperty(value = "duration", defaultValue = "1", required = true)
    private Float duration = 1.0f;

}
