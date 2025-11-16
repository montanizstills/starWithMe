package io.github.montanizstills.heygenAPI.model.character;

public enum AvatarStyle {
    Circle, CloseUp, Normal;

    private String style;

    AvatarStyle(){
        this.style = this.name().toLowerCase();
    }
}
