﻿//
// RestoreNuGetPackagesInNuGetIntegratedProject.cs
//
// Author:
//       Matt Ward <matt.ward@xamarin.com>
//
// Copyright (c) 2016 Xamarin Inc. (http://xamarin.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

using System.Threading;
using System.Threading.Tasks;
using MonoDevelop.Core;
using MonoDevelop.Projects;
using NuGet.ProjectManagement.Projects;

namespace MonoDevelop.PackageManagement
{
	internal class RestoreNuGetPackagesInNuGetIntegratedProject : IPackageAction
	{
		DotNetProject project;
		BuildIntegratedNuGetProject nugetProject;
		CancellationToken cancellationToken;
		MonoDevelopBuildIntegratedRestorer packageRestorer;
		IPackageManagementEvents packageManagementEvents;

		public RestoreNuGetPackagesInNuGetIntegratedProject (
			DotNetProject project,
			BuildIntegratedNuGetProject nugetProject,
			IMonoDevelopSolutionManager solutionManager,
			CancellationToken cancellationToken = default(CancellationToken))
		{
			this.project = project;
			this.nugetProject = nugetProject;
			this.cancellationToken = cancellationToken;
			packageManagementEvents = PackageManagementServices.PackageManagementEvents;

			packageRestorer = new MonoDevelopBuildIntegratedRestorer (
				SourceRepositoryProviderFactory.CreateSourceRepositoryProvider (),
				solutionManager.Settings,
				solutionManager.SolutionDirectory);
		}

		public void Execute ()
		{
			ExecuteAsync ().Wait ();
		}

		public bool HasPackageScriptsToRun ()
		{
			return false;
		}

		async Task ExecuteAsync ()
		{
			await packageRestorer.RestorePackages (nugetProject, cancellationToken);

			await Runtime.RunInMainThread (() => project.RefreshReferenceStatus ());

			packageManagementEvents.OnPackagesRestored ();
		}
	}
}

