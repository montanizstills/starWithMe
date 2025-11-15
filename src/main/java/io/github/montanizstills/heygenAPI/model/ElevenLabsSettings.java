package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

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

    public ElevenLabsSettings() {
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public Float getSimilarityBoost() {
        return similarityBoost;
    }

    public void setSimilarityBoost(Float similarityBoost) {
        this.similarityBoost = similarityBoost;
    }

    public Float getStability() {
        return stability;
    }

    public void setStability(Float stability) {
        this.stability = stability;
    }

    public Float getStyle() {
        return style;
    }

    public void setStyle(Float style) {
        this.style = style;
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
