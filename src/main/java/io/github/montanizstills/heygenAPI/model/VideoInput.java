package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.model.interfaces.BackgroundSettings;
import io.github.montanizstills.heygenAPI.model.interfaces.CharacterSettings;
import io.github.montanizstills.heygenAPI.model.interfaces.VoiceSettings;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class VideoInput {
    @JsonProperty("character")
    private CharacterSettings character;
    
    @JsonProperty("voice")
    private VoiceSettings voice;
    
    @JsonProperty("background")
    private BackgroundSettings background;
}
