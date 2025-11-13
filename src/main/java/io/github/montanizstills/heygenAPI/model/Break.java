package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

// ==================== Main Request Class ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class CreateAvatarVideoRequest {
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

    // Constructors
    public CreateAvatarVideoRequest() {}

    public CreateAvatarVideoRequest(List<VideoInput> videoInputs, Dimension dimension) {
        this.videoInputs = videoInputs;
        this.dimension = dimension;
    }

    // Getters and Setters
    public Boolean getCaption() { return caption; }
    public void setCaption(Boolean caption) { this.caption = caption; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getCallbackId() { return callbackId; }
    public void setCallbackId(String callbackId) { this.callbackId = callbackId; }

    public List<VideoInput> getVideoInputs() { return videoInputs; }
    public void setVideoInputs(List<VideoInput> videoInputs) { this.videoInputs = videoInputs; }

    public Dimension getDimension() { return dimension; }
    public void setDimension(Dimension dimension) { this.dimension = dimension; }

    public String getFolderId() { return folderId; }
    public void setFolderId(String folderId) { this.folderId = folderId; }

    public String getCallbackUrl() { return callbackUrl; }
    public void setCallbackUrl(String callbackUrl) { this.callbackUrl = callbackUrl; }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Video Input ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class VideoInput {
    @JsonProperty("character")
    private CharacterSettings character;

    @JsonProperty("voice")
    private VoiceSettings voice;

    @JsonProperty("background")
    private BackgroundSettings background;

    // Constructors
    public VideoInput() {}

    public VideoInput(VoiceSettings voice) {
        this.voice = voice;
    }

    public VideoInput(CharacterSettings character, VoiceSettings voice, BackgroundSettings background) {
        this.character = character;
        this.voice = voice;
        this.background = background;
    }

    // Getters and Setters
    public CharacterSettings getCharacter() { return character; }
    public void setCharacter(CharacterSettings character) { this.character = character; }

    public VoiceSettings getVoice() { return voice; }
    public void setVoice(VoiceSettings voice) { this.voice = voice; }

    public BackgroundSettings getBackground() { return background; }
    public void setBackground(BackgroundSettings background) { this.background = background; }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Dimension ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class Dimension {
    @JsonProperty("width")
    private Integer width;

    @JsonProperty("height")
    private Integer height;

    public Dimension() {}

    public Dimension(Integer width, Integer height) {
        this.width = width;
        this.height = height;
    }

    public Integer getWidth() { return width; }
    public void setWidth(Integer width) { this.width = width; }

    public Integer getHeight() { return height; }
    public void setHeight(Integer height) { this.height = height; }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Character Settings Interface ====================
interface CharacterSettings {}

// ==================== Avatar Settings ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class AvatarSettings implements CharacterSettings {
    @JsonProperty("type")
    private String type = "avatar";

    @JsonProperty("avatar_id")
    private String avatarId;

    @JsonProperty("scale")
    private Float scale = 1.0f;

    @JsonProperty("avatar_style")
    private String avatarStyle;

    @JsonProperty("offset")
    private Offset offset;

    @JsonProperty("matting")
    private Boolean matting;

    @JsonProperty("circle_background_color")
    private String circleBackgroundColor;

    // Constructors
    public AvatarSettings() {}

    public AvatarSettings(String avatarId) {
        this.avatarId = avatarId;
    }

    // Getters and Setters
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getAvatarId() { return avatarId; }
    public void setAvatarId(String avatarId) { this.avatarId = avatarId; }

    public Float getScale() { return scale; }
    public void setScale(Float scale) { this.scale = scale; }

    public String getAvatarStyle() { return avatarStyle; }
    public void setAvatarStyle(String avatarStyle) { this.avatarStyle = avatarStyle; }

    public Offset getOffset() { return offset; }
    public void setOffset(Offset offset) { this.offset = offset; }

    public Boolean getMatting() { return matting; }
    public void setMatting(Boolean matting) { this.matting = matting; }

    public String getCircleBackgroundColor() { return circleBackgroundColor; }
    public void setCircleBackgroundColor(String circleBackgroundColor) {
        this.circleBackgroundColor = circleBackgroundColor;
    }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Talking Photo Settings ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class TalkingPhotoSettings implements CharacterSettings {
    @JsonProperty("type")
    private String type = "talking_photo";

    @JsonProperty("talking_photo_id")
    private String talkingPhotoId;

    @JsonProperty("scale")
    private Float scale = 1.0f;

    @JsonProperty("talking_photo_style")
    private String talkingPhotoStyle;

    @JsonProperty("offset")
    private Offset offset;

    @JsonProperty("talking_style")
    private String talkingStyle;

    @JsonProperty("expression")
    private String expression;

    @JsonProperty("super_resolution")
    private Boolean superResolution;

    @JsonProperty("matting")
    private Boolean matting;

    @JsonProperty("circle_background_color")
    private String circleBackgroundColor;

    // Constructors
    public TalkingPhotoSettings() {}

    public TalkingPhotoSettings(String talkingPhotoId) {
        this.talkingPhotoId = talkingPhotoId;
    }

    // Getters and Setters
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getTalkingPhotoId() { return talkingPhotoId; }
    public void setTalkingPhotoId(String talkingPhotoId) { this.talkingPhotoId = talkingPhotoId; }

    public Float getScale() { return scale; }
    public void setScale(Float scale) { this.scale = scale; }

    public String getTalkingPhotoStyle() { return talkingPhotoStyle; }
    public void setTalkingPhotoStyle(String talkingPhotoStyle) {
        this.talkingPhotoStyle = talkingPhotoStyle;
    }

    public Offset getOffset() { return offset; }
    public void setOffset(Offset offset) { this.offset = offset; }

    public String getTalkingStyle() { return talkingStyle; }
    public void setTalkingStyle(String talkingStyle) { this.talkingStyle = talkingStyle; }

    public String getExpression() { return expression; }
    public void setExpression(String expression) { this.expression = expression; }

    public Boolean getSuperResolution() { return superResolution; }
    public void setSuperResolution(Boolean superResolution) { this.superResolution = superResolution; }

    public Boolean getMatting() { return matting; }
    public void setMatting(Boolean matting) { this.matting = matting; }

    public String getCircleBackgroundColor() { return circleBackgroundColor; }
    public void setCircleBackgroundColor(String circleBackgroundColor) {
        this.circleBackgroundColor = circleBackgroundColor;
    }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Offset ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class Offset {
    @JsonProperty("x")
    private Float x = 0.0f;

    @JsonProperty("y")
    private Float y = 0.0f;

    public Offset() {}

    public Offset(Float x, Float y) {
        this.x = x;
        this.y = y;
    }

    public Float getX() { return x; }
    public void setX(Float x) { this.x = x; }

    public Float getY() { return y; }
    public void setY(Float y) { this.y = y; }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Voice Settings Interface ====================
interface VoiceSettings {}

// ==================== Text Voice Settings ====================
@Setter
@Getter
@JsonInclude(JsonInclude.Include.NON_NULL)
class TextVoiceSettings implements VoiceSettings {
    // Getters and Setters
    @JsonProperty("type")
    private String type = "text";

    @JsonProperty("voice_id")
    private String voiceId;

    @JsonProperty("input_text")
    private String inputText;

    @JsonProperty("speed")
    private Float speed = 1.0f;

    @JsonProperty("pitch")
    private Integer pitch = 0;

    @JsonProperty("emotion")
    private String emotion;

    @JsonProperty("locale")
    private String locale;

    @JsonProperty("elevenlabs_settings")
    private ElevenLabsSettings elevenLabsSettings;

    // Constructors
    public TextVoiceSettings() {}

    public TextVoiceSettings(String voiceId, String inputText) {
        this.voiceId = voiceId;
        this.inputText = inputText;
    }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== ElevenLabs Settings ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class ElevenLabsSettings {
    @JsonProperty("model")
    private String model;

    @JsonProperty("similarity_boost")
    private Float similarityBoost;

    @JsonProperty("stability")
    private Float stability;

    @JsonProperty("style")
    private Float style;

    public ElevenLabsSettings() {}

    public String getModel() { return model; }
    public void setModel(String model) { this.model = model; }

    public Float getSimilarityBoost() { return similarityBoost; }
    public void setSimilarityBoost(Float similarityBoost) { this.similarityBoost = similarityBoost; }

    public Float getStability() { return stability; }
    public void setStability(Float stability) { this.stability = stability; }

    public Float getStyle() { return style; }
    public void setStyle(Float style) { this.style = style; }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Audio Voice Settings ====================
@Setter
@Getter
@JsonInclude(JsonInclude.Include.NON_NULL)
class AudioVoiceSettings implements VoiceSettings {
    @JsonProperty("type")
    private String type = "audio";

    @JsonProperty("audio_url")
    private String audioUrl;

    @JsonProperty("audio_asset_id")
    private String audioAssetId;

    public AudioVoiceSettings() {}

    public AudioVoiceSettings(String audioUrl, String audioAssetId) {
        this.audioUrl = audioUrl;
        this.audioAssetId = audioAssetId;
    }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Silence Voice Settings ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class SilenceVoiceSettings implements VoiceSettings {
    @JsonProperty("type")
    private String type = "silence";

    @JsonProperty("duration")
    private Float duration = 1.0f;

    public SilenceVoiceSettings() {}

    public SilenceVoiceSettings(Float duration) {
        this.duration = duration;
    }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public Float getDuration() { return duration; }
    public void setDuration(Float duration) { this.duration = duration; }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Background Settings Interface ====================
interface BackgroundSettings {}

// ==================== Color Background ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class ColorBackground implements BackgroundSettings {
    @JsonProperty("type")
    private String type = "color";

    @JsonProperty("value")
    private String value = "#f6f6fc";

    public ColorBackground() {}

    public ColorBackground(String value) {
        this.value = value;
    }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Image Background ====================
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

    public ImageBackground() {}

    public ImageBackground(String url, String imageAssetId) {
        this.url = url;
        this.imageAssetId = imageAssetId;
    }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }

    public String getImageAssetId() { return imageAssetId; }
    public void setImageAssetId(String imageAssetId) { this.imageAssetId = imageAssetId; }

    public String getFit() { return fit; }
    public void setFit(String fit) { this.fit = fit; }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Video Background ====================
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

    public VideoBackground() {}

    public VideoBackground(String url, String videoAssetId, String playStyle) {
        this.url = url;
        this.videoAssetId = videoAssetId;
        this.playStyle = playStyle;
    }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }

    public String getVideoAssetId() { return videoAssetId; }
    public void setVideoAssetId(String videoAssetId) { this.videoAssetId = videoAssetId; }

    public String getPlayStyle() { return playStyle; }
    public void setPlayStyle(String playStyle) { this.playStyle = playStyle; }

    public String getFit() { return fit; }
    public void setFit(String fit) { this.fit = fit; }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Response Class ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class CreateAvatarVideoResponse {
    @JsonProperty("video_id")
    private String videoId;

    public CreateAvatarVideoResponse() {}

    public String getVideoId() { return videoId; }
    public void setVideoId(String videoId) { this.videoId = videoId; }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

// ==================== Usage Example ====================
class HeyGenAPIExample {
    public static void main(String[] args) {
        // Create a simple avatar video request
        TextVoiceSettings voice = new TextVoiceSettings("voice_id_123", "Hello, this is a test video!");
        AvatarSettings avatar = new AvatarSettings("avatar_id_456");
        ColorBackground background = new ColorBackground("#ffffff");

        VideoInput videoInput = new VideoInput(avatar, voice, background);
        Dimension dimension = new Dimension(1920, 1080);

        CreateAvatarVideoRequest request = new CreateAvatarVideoRequest(
                List.of(videoInput),
                dimension
        );
        request.setTitle("My Test Video");
        request.setCaption(true);

        // Convert to JSON
        System.out.println(request.toString());
    }
}