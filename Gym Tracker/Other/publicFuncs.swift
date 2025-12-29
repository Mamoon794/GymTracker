//
//  publicFuncs.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-12-29.
//

import SwiftUI

func exerciseRow(_ exercise: Exercise) -> some View{
    HStack(spacing: 12) {
        Image(systemName: exercise.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .foregroundStyle(.tint)

        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            Text("Sets: \(exercise.totalSets)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        Spacer()
    }
    .padding(.vertical, 6)
}
