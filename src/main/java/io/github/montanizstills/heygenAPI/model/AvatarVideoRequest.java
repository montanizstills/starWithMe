package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.VideoInput;
import io.github.montanizstills.heygenAPI.model.interfaces.Request;
import io.github.montanizstills.heygenAPI.model.interfaces.VoiceSettings;
import lombok.*;

import java.util.List;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AvatarVideoRequest implements Request {
    @JsonProperty("caption")
    private Boolean caption;

    @JsonProperty("title")
    private String title;

    @JsonProperty("callback_id")
    private String callbackId;

    @JsonProperty("video_inputs")
    private List<VideoInput> videoInputs;

    @JsonProperty("dimension")
    private Dimension dimension;

    @JsonProperty("folder_id")
    private String folderId;

    @JsonProperty("callback_url")
    private String callbackUrl;

}
