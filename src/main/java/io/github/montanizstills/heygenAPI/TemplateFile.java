package io.github.montanizstills.heygenAPI;

import lombok.*;

@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TemplateFile {
    private String topic;
    private String audience;
    private String musicTheme;
    private String videoLength;
    private String videoOrientation;
    private String scriptPlan;
    private String targetLanguage;
    private String avatar;
    private String voice;
    private String supplementalFootageBRoll;
    private String captions;
}
