package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.model.interfaces.VoiceSettings;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AudioVoiceSettings implements VoiceSettings {
    @JsonProperty("type")
    private String type = "audio";

    @JsonProperty("audio_url")
    private String audioUrl;

    @JsonProperty("audio_asset_id")
    private String audioAssetId;

}
