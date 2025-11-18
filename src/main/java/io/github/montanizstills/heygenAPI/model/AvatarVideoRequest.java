package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.interfaces.IRequest;
import lombok.*;

import java.util.List;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AvatarVideoRequest implements IRequest {
    @JsonProperty(value = "caption", defaultValue = "False")
    private Boolean caption;

    @JsonProperty("title")
    private String title;

    @JsonProperty("callback_id")
    private String callbackId;

    @JsonProperty(value = "video_inputs", required = true)
    private List videoInputs; //todo - introduce class to parameterize List

    @JsonProperty("dimension")
    private Dimension dimension;

    @JsonProperty("folder_id")
    private String folderId;

    @JsonProperty("callback_url")
    private String callbackUrl;

}
