package io.github.montanizstills.heygenAPI.model.background;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class BackgroundSettings implements IBackgroundSettings {
    @JsonProperty(value = "type", required = true)
    private BackgroundType type;

    @JsonProperty(value = "value", defaultValue = "#FFFFFF", required = true)
    private String value; // todo - Applies only to color type.

    @JsonProperty(value = "url", required = true)
    private String url; // todo - Applies only to image or video type.

    @JsonProperty(value = "image_asset_id", required = true)
    private String imageAssetId; // todo - Either url or image_asset_id must be provided. Omitting both or defining both will result in an error. Applies only to image type.

    @JsonProperty(value = "video_asset_id", required = true)
    private String videoAssetId; // todo - Either url or video_asset_id must be provided. Omitting both or defining both will result in an error. Applies only to video type.

    @JsonProperty(value = "play_style", required = true)
    private PlayStyle playStyle;

    @JsonProperty("fit")
    private Fit fit;
}
