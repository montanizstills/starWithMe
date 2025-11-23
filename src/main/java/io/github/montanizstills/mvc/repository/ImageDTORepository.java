package io.github.montanizstills.mvc.repository;

import io.github.montanizstills.mvc.model.ImageGenerationDTO;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ImageDTORepository extends CrudRepository<ImageGenerationDTO, Long> {
}
