package io.github.montanizstills.heygenAPI.model.photo;

import io.github.montanizstills.heygenAPI.json.JsonEnum;

public enum Pose implements JsonEnum {
    Half_Body, Close_Up, Full_Body;

    private final String pose;

    Pose() {
        this.pose = this.name().toLowerCase();
    }

    @Override
    public String getValue() {
        return this.pose;
    }
}
