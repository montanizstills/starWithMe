package io.github.montanizstills.heygenAPI.model.photo;

import io.github.montanizstills.heygenAPI.json.JsonEnum;

public enum Style implements JsonEnum {
    Realistic, Pixar, Cinematic, Vintage, Noir, CyberPunk, Unspecified;

    private final String value;

    Style() {
        this.value = this.name().toLowerCase();
    }

    @Override
    public String getValue() {
        return this.value;
    }
}
