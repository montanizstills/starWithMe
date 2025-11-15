package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.model.interfaces.BackgroundSettings;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
class ImageBackground implements BackgroundSettings {
    @JsonProperty("type")
    private String type = "image";

    @JsonProperty("url")
    private String url;

    @JsonProperty("image_asset_id")
    private String imageAssetId;

    @JsonProperty("fit")
    private String fit = "cover";

}
