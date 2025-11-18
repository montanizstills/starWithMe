package io.github.montanizstills.heygenAPI.model.photo;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class PhotoSettings implements IPhotoSettings {
    @JsonProperty(value = "name", required = true)
    private String name;

    @JsonProperty(value = "age", required = true)
    private Age age;

    @JsonProperty(value = "gender", required = true)
    private Gender gender;

    @JsonProperty(value = "ethnicity", required = true)
    private Ethnicity ethnicity;

    @JsonProperty(value = "orientation", required = true)
    private Orientation orientation;

    @JsonProperty(value = "pose", required = true)
    private Pose pose;

    @JsonProperty(value = "style", required = true)
    private Style style;

    @JsonProperty(value = "appearance", required = true)
    private String appearance; // todo - maximum 1000 characters;

    @JsonProperty(value = "callback_url")
    private String callback_url; // todo - f both webhook and callback_url are used, events will be sent to both endpoints.

    @JsonProperty(value = "callback_id")
    private String callback_id;
}
