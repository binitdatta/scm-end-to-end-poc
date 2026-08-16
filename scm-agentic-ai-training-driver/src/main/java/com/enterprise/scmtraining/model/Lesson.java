package com.enterprise.scmtraining.model;

import java.util.List;

public record Lesson(
        int number,
        String slug,
        String title,
        String shortTitle,
        String duration,
        String category,
        String objective,
        String keyMessage,
        List<String> concepts,
        List<String> flow,
        List<String> demoSteps,
        List<String> takeaways
) {
}
