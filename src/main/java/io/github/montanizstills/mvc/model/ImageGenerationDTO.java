package io.github.montanizstills.mvc.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
//@Table(name = "ImageGeneration")
public class ImageGenerationDTO {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO, generator = "uuid2")
    private Long id;
    private String generationID;
    private String error;

}
