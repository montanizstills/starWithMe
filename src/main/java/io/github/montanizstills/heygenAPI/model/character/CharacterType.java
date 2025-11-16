package io.github.montanizstills.heygenAPI.model.character;

public enum CharacterType {
    AVATAR, TALKING_PHOTO;

    private final String type;

    CharacterType() {
        this.type = this.name().toLowerCase();
    }

}
