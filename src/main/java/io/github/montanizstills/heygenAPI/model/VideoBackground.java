package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.model.interfaces.BackgroundSettings;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
class VideoBackground implements BackgroundSettings {
    @JsonProperty("type")
    private String type = "video";

    @JsonProperty("url")
    private String url;

    @JsonProperty("video_asset_id")
    private String videoAssetId;

    @JsonProperty("play_style")
    private String playStyle;

    @JsonProperty("fit")
    private String fit = "cover";

}

