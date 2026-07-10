import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { ReactiveFormsModule } from '@angular/forms';
import { ConfirmationService } from 'primeng/api';
import { ButtonModule } from 'primeng/button';
import { ConfirmDialogModule } from 'primeng/confirmdialog';
import { GalleriaModule } from 'primeng/galleria';
import { InputNumberModule } from 'primeng/inputnumber';
import { InputTextModule } from 'primeng/inputtext';
import { ProgressSpinnerModule } from 'primeng/progressspinner';
import { SelectModule } from 'primeng/select';
import { TagModule } from 'primeng/tag';
import { TextareaModule } from 'primeng/textarea';

import { SharedModule } from '../../utils/shared.module';
import { MenuDetailComponent } from './pages/menu-detail.component';
import { MenuFormComponent } from './pages/menu-form.component';
import { MenuListComponent } from './pages/menu-list.component';
import { MenuRoutingModule } from './menu-routing.module';

@NgModule({
	declarations: [MenuListComponent, MenuDetailComponent, MenuFormComponent],
	imports: [
		CommonModule,
		MenuRoutingModule,
		SharedModule,
		ReactiveFormsModule,
		ButtonModule,
		ConfirmDialogModule,
		GalleriaModule,
		InputNumberModule,
		InputTextModule,
		ProgressSpinnerModule,
		SelectModule,
		TagModule,
		TextareaModule,
	],
	providers: [ConfirmationService],
})
export class MenuModule {}
