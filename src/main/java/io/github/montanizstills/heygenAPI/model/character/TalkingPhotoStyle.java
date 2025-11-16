package io.github.montanizstills.heygenAPI.model.character;

import io.github.montanizstills.heygenAPI.utils.JsonEnum;

public enum TalkingPhotoStyle implements JsonEnum {
    Circle, Square;

    private String talkingPhotoStyle;

    TalkingPhotoStyle() {
        this.talkingPhotoStyle = this.name().toLowerCase();
    }

    @Override
    public String getValue() {
        return this.talkingPhotoStyle;
    }

    @Override
    public String toJson() {
        return JsonEnum.super.toJson();
    }
}
