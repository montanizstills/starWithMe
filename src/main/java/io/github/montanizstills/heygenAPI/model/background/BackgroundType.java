package io.github.montanizstills.heygenAPI.model.background;

import io.github.montanizstills.heygenAPI.utils.JsonEnum;

public enum BackgroundType implements JsonEnum {
    Color, Image, Video;
    private String backgroundType;

    BackgroundType() {
        this.backgroundType = this.name().toLowerCase();
    }

    @Override
    public String getValue() {
        return this.backgroundType;
    }

    @Override
    public String toJson() {
        return JsonEnum.super.toJson();
    }
}
