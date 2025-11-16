package io.github.montanizstills.heygenAPI.model.voice;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class VoiceSettings implements IVoiceSettings {
    @JsonProperty(value = "type", required = true)
    private VoiceType type;

    @JsonProperty(value = "voice_id", required = true)
    private String voiceId; // todo - Applies only to the text type.

    @JsonProperty(value = "input_text", required = true)
    private String inputText; // todo - Applies only to the text type.

    @JsonProperty(value = "speed", defaultValue = "1")
    private Float speed = 1.0f; // todo - Voice speed, value ranges from 0.5 to 1.5. Applies only to text type

    @JsonProperty(value = "pitch", defaultValue = "1")
    private Integer pitch = 0; // todo - Voice pitch, value ranges from -50 to 50. Applies only to text type.

    @JsonProperty("emotion")
    private Emotion emotion; // todo - Applies only to text type.

    @JsonProperty("locale")
    private String locale; // todo - Applies only to text type.

    @JsonProperty("elevenlabs_settings")
    private ElevenLabsSettings elevenLabsSettings;

    @JsonProperty(value = "audio_url", required = true)
    private String audioUrl; // todo - Either audio_url or audio_asset_id must be provided. Omitting both or defining both will result in an error. Applies only to audio type.

    @JsonProperty(value = "audio_asset_id", required = true)
    private String audioAssetId; // todo - Either audio_url or audio_asset_id must be provided. Omitting both or defining both will result in an error. Applies only to audio type.

    @JsonProperty(value = "duration", defaultValue = "1", required = true)
    private Float duration = 1.0f; // todo - value ranges from 1.0 and 100.0. Applies only to silence type.

}
