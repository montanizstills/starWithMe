package io.github.montanizstills.heygenAPI.model.background;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.interfaces.IBackgroundSettings;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class BackgroundSettings implements IBackgroundSettings {
    @JsonProperty(value = "type", required = true)
    private String type;

    @JsonProperty(value = "value", defaultValue = "#FFFFFF", required = true)
    private String value;

    @JsonProperty(value = "url", required = true)
    private String url;

    @JsonProperty(value = "image_asset_id", required = true)
    private String imageAssetId;

    @JsonProperty(value = "video_asset_id", required = true)
    private String videoAssetId;

    @JsonProperty(value = "play_style", required = true)
    private String playStyle;

    @JsonProperty("fit")
    private String fit;
}
